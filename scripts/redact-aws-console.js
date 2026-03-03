/**
 * redact-aws-console.js — DOM injection for AWS Console sensitive data redaction
 *
 * Usage: Injected via Claude Code's javascript_tool MCP before screenshots.
 * The e2e-deployment-orchestration skill calls this automatically during
 * visual verification phases.
 *
 * What it redacts:
 *   - AWS Account IDs (12-digit)
 *   - SSO Instance IDs (ssoins-*)
 *   - Organization IDs (o-*)
 *   - IAM Identity Store IDs (d-*)
 *   - ARNs (arn:aws:*)
 *   - Email addresses (*@*.io, *@*.com)
 *   - Root IDs (r-*)
 *   - Issuer URLs containing SSO instance refs
 *
 * Copyright 2026 nnthanh101@gmail.com (oceansoft.io). Licensed under Apache-2.0.
 */
(function redactAwsConsole() {
  'use strict';

  const PATTERNS = [
    // Account IDs (12-digit, with and without dashes)
    [/\b\d{12}\b/g, '***-REDACTED-***'],
    [/\b\d{4}-\d{4}-\d{4}\b/g, '****-****-****'],

    // SSO Instance IDs
    [/ssoins-[a-f0-9]{16,}/g, 'ssoins-********************'],
    [/\b[a-f0-9]{16,18}\b(?![-])/g, '********************'],

    // Organization and Root IDs
    [/o-[a-z0-9]{10,}/g, 'o-**********'],
    [/r-[a-z0-9]{4,}/g, 'r-****'],

    // Identity Store IDs
    [/d-[a-f0-9]{10,}/g, 'd-**********'],

    // ARNs (redact everything after the resource type)
    [/arn:aws:sso[^"<\s]*/g, 'arn:aws:sso:::***REDACTED***'],
    [/arn:aws:iam[^"<\s]*/g, 'arn:aws:iam:::***REDACTED***'],

    // Email addresses
    [/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g, '***@***.io'],

    // Issuer URLs with SSO refs
    [/https:\/\/identitycenter\.amazonaws\.com\/ssoins[^"<\s]*/g,
     'https://identitycenter.amazonaws.com/***REDACTED***'],

    // Permission Set IDs
    [/ps-[a-f0-9]{6,}/g, 'ps-*******']
  ];

  // Walk all text nodes in the DOM
  var walker = document.createTreeWalker(
    document.body, NodeFilter.SHOW_TEXT, null, false
  );
  var node;
  var count = 0;
  while (node = walker.nextNode()) {
    var text = node.textContent;
    var changed = false;
    for (var i = 0; i < PATTERNS.length; i++) {
      var pat = PATTERNS[i][0];
      var rep = PATTERNS[i][1];
      if (pat.test(text)) {
        text = text.replace(pat, rep);
        changed = true;
      }
      pat.lastIndex = 0; // reset global regex
    }
    if (changed) {
      node.textContent = text;
      count++;
    }
  }

  // Blur the account selector in the AWS nav bar
  var navAccount = document.querySelector(
    '[data-testid="awsc-nav-account-menu-button"]'
  );
  if (navAccount) navAccount.style.filter = 'blur(5px)';

  return 'Redacted ' + count + ' text nodes';
})();
