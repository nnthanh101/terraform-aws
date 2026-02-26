# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0.
# APRA CPS 234 compliance checks for IAM Identity Center resources.
# Para 15: Data classification tagging
# Para 36: Least privilege (no AdministratorAccess)
# Para 37: Session duration controls

from __future__ import annotations

from checkov.common.models.enums import CheckCategories, CheckResult
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck

VALID_DATA_CLASSIFICATIONS = {"public", "internal", "confidential", "restricted"}


class APRADataClassificationCheck(BaseResourceCheck):
    """CPS 234 Para 15: All IAM resources must have data_classification tag."""

    def __init__(self) -> None:
        name = "Ensure APRA CPS 234 data_classification tag is present with valid value"
        id = "CKV_APRA_001"
        supported_resources = ["aws_ssoadmin_permission_set"]
        categories = [CheckCategories.GENERAL_SECURITY]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf: dict) -> CheckResult:
        tags = conf.get("tags", [{}])
        if isinstance(tags, list):
            tags = tags[0] if tags else {}
        if not isinstance(tags, dict):
            return CheckResult.FAILED

        classification = tags.get("data_classification", [None])
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
        # Parse ISO 8601 duration (PT1H, PT4H, PT8H, PT12H)
        if duration_str.startswith("PT") and duration_str.endswith("H"):
            try:
                hours = int(duration_str[2:-1])
                return CheckResult.PASSED if hours <= self.MAX_DURATION_HOURS else CheckResult.FAILED
            except ValueError:
                return CheckResult.UNKNOWN

        return CheckResult.UNKNOWN


check_data_classification = APRADataClassificationCheck()
check_least_privilege = APRALeastPrivilegeCheck()
check_session_duration = APRASessionDurationCheck()
