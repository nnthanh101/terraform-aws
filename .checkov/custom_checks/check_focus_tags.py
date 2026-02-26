# Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0.
# FOCUS 1.2+ FinOps tag compliance check for Terraform resources.
# Validates required cost attribution tags per FOCUS 1.2+ specification.

from __future__ import annotations

import ast
import re

from checkov.common.models.enums import CheckCategories, CheckResult
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck

FOCUS_REQUIRED_TAGS = ["x_cost_center", "x_project", "x_environment", "x_service_name"]

# Resources that support tags in aws_ssoadmin / aws_identitystore
TAGGABLE_RESOURCES = [
    "aws_ssoadmin_permission_set",
]


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


class FocusTagComplianceCheck(BaseResourceCheck):
    def __init__(self) -> None:
        name = "Ensure FOCUS 1.2+ required tags are present for cost attribution"
        id = "CKV_CUSTOM_FOCUS_001"
        supported_resources = TAGGABLE_RESOURCES
        categories = [CheckCategories.GENERAL_SECURITY]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf: dict) -> CheckResult:
        tags = _resolve_tags(conf)

        missing = [t for t in FOCUS_REQUIRED_TAGS if t not in tags]
        if missing:
            self.details.append(f"Missing FOCUS 1.2+ tags: {', '.join(missing)}")
            return CheckResult.FAILED
        return CheckResult.PASSED


check = FocusTagComplianceCheck()
