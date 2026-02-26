# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0.
# FOCUS 1.2+ FinOps tag compliance check for Terraform resources.
# Validates required cost attribution tags per FOCUS 1.2+ specification.

from __future__ import annotations

from checkov.common.models.enums import CheckCategories, CheckResult
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck

FOCUS_REQUIRED_TAGS = ["x_cost_center", "x_project", "x_environment", "x_service_name"]

# Resources that support tags in aws_ssoadmin / aws_identitystore
TAGGABLE_RESOURCES = [
    "aws_ssoadmin_permission_set",
]


class FocusTagComplianceCheck(BaseResourceCheck):
    def __init__(self) -> None:
        name = "Ensure FOCUS 1.2+ required tags are present for cost attribution"
        id = "CKV_CUSTOM_FOCUS_001"
        supported_resources = TAGGABLE_RESOURCES
        categories = [CheckCategories.GENERAL_SECURITY]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf: dict) -> CheckResult:
        tags = conf.get("tags", [{}])
        if isinstance(tags, list):
            tags = tags[0] if tags else {}
        if not isinstance(tags, dict):
            return CheckResult.FAILED

        missing = [t for t in FOCUS_REQUIRED_TAGS if t not in tags]
        if missing:
            self.details.append(f"Missing FOCUS 1.2+ tags: {', '.join(missing)}")
            return CheckResult.FAILED
        return CheckResult.PASSED


check = FocusTagComplianceCheck()
