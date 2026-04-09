import pytest

from deployer.runner import parse_plan_summary


def test_parse_plan_summary_deploy():
    lines = [
        "Terraform will perform the following actions:",
        "  # aci_tenant.example will be created",
        "Plan: 5 to add, 0 to change, 2 to destroy.",
    ]
    s = parse_plan_summary(lines)
    assert s.to_add == 5
    assert s.to_change == 0
    assert s.to_destroy == 2


def test_parse_plan_summary_no_changes():
    lines = [
        "No changes. Your infrastructure matches the configuration.",
    ]
    s = parse_plan_summary(lines)
    assert s.to_add == 0
    assert s.to_change == 0
    assert s.to_destroy == 0


def test_parse_plan_summary_empty():
    s = parse_plan_summary([])
    assert s.to_add == 0
    assert s.to_change == 0
    assert s.to_destroy == 0


def test_parse_plan_summary_uses_last_match():
    lines = [
        "Plan: 1 to add, 0 to change, 0 to destroy.",
        "some other output",
        "Plan: 3 to add, 1 to change, 0 to destroy.",
    ]
    s = parse_plan_summary(lines)
    assert s.to_add == 3
    assert s.to_change == 1


def test_total_for_deploy():
    lines = ["Plan: 4 to add, 2 to change, 1 to destroy."]
    s = parse_plan_summary(lines)
    assert s.total_for_deploy == 6


def test_total_for_destroy():
    lines = ["Plan: 0 to add, 0 to change, 7 to destroy."]
    s = parse_plan_summary(lines)
    assert s.total_for_destroy == 7
