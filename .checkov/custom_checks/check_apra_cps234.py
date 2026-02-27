# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0.
# APRA CPS 234 compliance checks for IAM Identity Center resources.
# Para 15: Data classification tagging
# Para 36: Least privilege (no AdministratorAccess); SoD (admin session <= 1H)
# Para 37: Session duration controls; high-privilege permissions boundary

from __future__ import annotations

import ast
import re

from checkov.common.models.enums import CheckCategories, CheckResult
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck

VALID_DATA_CLASSIFICATIONS = {"public", "internal", "confidential", "restricted"}


def _resolve_tags(conf: dict) -> dict:
    """Extract a tags dict from a resource conf, handling merge() expressions.

    Checkov resolves variable references and locals but cannot evaluate Terraform
    built-in functions such as merge(). When a resource uses:
        tags = merge(local._effective_default_tags, lookup(each.value, "tags", {}))
    checkov stores a string like:
        "${merge(${merge({'key': 'val', ...}, {})}, lookup(...))}"
    This helper extracts all non-nested dict literals from that string and merges
    them so the check can validate tags guaranteed by local._effective_default_tags.
    """
    tags = conf.get("tags", [{}])
    if isinstance(tags, list):
        tags = tags[0] if tags else {}

    if isinstance(tags, dict):
        return tags

    # tags is a string expression — extract all non-nested dict literals
    tags_str = str(tags)
    merged: dict = {}
    for match in re.findall(r"\{[^{}]*\}", tags_str):
        try:
            candidate = ast.literal_eval(match)
            if isinstance(candidate, dict):
                merged.update(candidate)
        except (ValueError, SyntaxError):
            pass

    return merged


class APRADataClassificationCheck(BaseResourceCheck):
    """CPS 234 Para 15: All IAM resources must have DataClassification tag."""

    def __init__(self) -> None:
        name = "Ensure APRA CPS 234 DataClassification tag is present with valid value"
        id = "CKV_APRA_001"
        supported_resources = ["aws_ssoadmin_permission_set", "aws_ssoadmin_application"]
        categories = [CheckCategories.GENERAL_SECURITY]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf: dict) -> CheckResult:
        tags = _resolve_tags(conf)

        classification = tags.get("DataClassification", [None])
        if isinstance(classification, list):
            classification = classification[0] if classification else None

        if classification and str(classification).lower() in VALID_DATA_CLASSIFICATIONS:
            return CheckResult.PASSED
        return CheckResult.FAILED


class APRALeastPrivilegeCheck(BaseResourceCheck):
    """CPS 234 Para 36: No AdministratorAccess without documented justification."""

    def __init__(self) -> None:
        name = "Ensure no AdministratorAccess AWS managed policy is attached"
        id = "CKV_APRA_002"
        supported_resources = ["aws_ssoadmin_managed_policy_attachment"]
        categories = [CheckCategories.IAM]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf: dict) -> CheckResult:
        policy_arn = conf.get("managed_policy_arn", [""])
        if isinstance(policy_arn, list):
            policy_arn = policy_arn[0] if policy_arn else ""

        if "AdministratorAccess" in str(policy_arn):
            return CheckResult.FAILED
        return CheckResult.PASSED


class APRASessionDurationCheck(BaseResourceCheck):
    """CPS 234 Para 37: Session duration must not exceed 8 hours."""

    MAX_DURATION_HOURS = 8

    def __init__(self) -> None:
        name = "Ensure SSO session duration does not exceed 8 hours"
        id = "CKV_APRA_003"
        supported_resources = ["aws_ssoadmin_permission_set"]
        categories = [CheckCategories.GENERAL_SECURITY]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf: dict) -> CheckResult:
        duration = conf.get("session_duration", [None])
        if isinstance(duration, list):
            duration = duration[0] if duration else None

        if duration is None:
            return CheckResult.PASSED  # Default is 1 hour

        duration_str = str(duration)
        # Parse ISO 8601 duration — hours format (PT1H, PT4H, PT8H, PT12H)
        if duration_str.startswith("PT") and duration_str.endswith("H"):
            try:
                hours = int(duration_str[2:-1])
                return CheckResult.PASSED if hours <= self.MAX_DURATION_HOURS else CheckResult.FAILED
            except ValueError:
                return CheckResult.UNKNOWN
        # Parse ISO 8601 duration — minutes format (PT30M, PT480M)
        elif duration_str.startswith("PT") and duration_str.endswith("M"):
            try:
                minutes = int(duration_str[2:-1])
                return CheckResult.PASSED if minutes / 60 <= self.MAX_DURATION_HOURS else CheckResult.FAILED
            except ValueError:
                return CheckResult.UNKNOWN

        return CheckResult.UNKNOWN


class APRASeparationOfDutiesCheck(BaseResourceCheck):
    """CPS 234 Para 36: Administrative permission sets must have short session duration (SoD control)."""

    ADMIN_MAX_HOURS = 1

    def __init__(self) -> None:
        name = "Ensure administrative permission sets have session duration <= 1 hour (SoD)"
        id = "CKV_APRA_004"
        supported_resources = ["aws_ssoadmin_permission_set"]
        categories = [CheckCategories.IAM]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf: dict) -> CheckResult:
        name = conf.get("name", [""])
        if isinstance(name, list):
            name = name[0] if name else ""
        name_str = str(name).lower()

        # Only check permission sets with administrative naming patterns
        if "admin" not in name_str:
            return CheckResult.PASSED

        duration = conf.get("session_duration", [None])
        if isinstance(duration, list):
            duration = duration[0] if duration else None

        if duration is None:
            return CheckResult.PASSED  # Default 1 hour is compliant

        duration_str = str(duration)
        if duration_str.startswith("PT") and duration_str.endswith("H"):
            try:
                hours = int(duration_str[2:-1])
                return CheckResult.PASSED if hours <= self.ADMIN_MAX_HOURS else CheckResult.FAILED
            except ValueError:
                return CheckResult.UNKNOWN
        elif duration_str.startswith("PT") and duration_str.endswith("M"):
            try:
                minutes = int(duration_str[2:-1])
                return CheckResult.PASSED if minutes / 60 <= self.ADMIN_MAX_HOURS else CheckResult.FAILED
            except ValueError:
                return CheckResult.UNKNOWN

        return CheckResult.UNKNOWN


class APRASessionMFAAlignmentCheck(BaseResourceCheck):
    """CPS 234 Para 37: High-privilege permission sets should have a permissions boundary."""

    HIGH_PRIVILEGE_PATTERNS = ["administratoraccess", "poweruseraccess"]

    def __init__(self) -> None:
        name = "Ensure high-privilege permission sets have a permissions boundary"
        id = "CKV_APRA_005"
        supported_resources = ["aws_ssoadmin_permission_set"]
        categories = [CheckCategories.IAM]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf: dict) -> CheckResult:
        name = conf.get("name", [""])
        if isinstance(name, list):
            name = name[0] if name else ""
        name_str = str(name).lower()

        # Only applies to high-privilege permission sets
        is_high_privilege = any(pattern in name_str for pattern in self.HIGH_PRIVILEGE_PATTERNS)
        if not is_high_privilege:
            return CheckResult.PASSED

        # Check for permissions_boundary
        boundary = conf.get("permissions_boundary", [None])
        if isinstance(boundary, list):
            boundary = boundary[0] if boundary else None

        # High-privilege sets without boundary fail
        # Note: This is advisory — LZ break-glass admin may skip with checkov:skip + ADR-020 reference
        if boundary is None:
            return CheckResult.FAILED
        return CheckResult.PASSED


check_data_classification = APRADataClassificationCheck()
check_least_privilege = APRALeastPrivilegeCheck()
check_session_duration = APRASessionDurationCheck()
check_separation_of_duties = APRASeparationOfDutiesCheck()
check_session_mfa_alignment = APRASessionMFAAlignmentCheck()
