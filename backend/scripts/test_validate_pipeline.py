"""
pytest tests for validate_pipeline.py — assertion evaluator and config loader.

TDD RED phase: these tests will fail to import until validate_pipeline.py exists.
After Task 2 (validate_pipeline.py), these tests must pass green without a DB connection.

Coverage: evaluate_assertions() and load_config() only — NO database connectivity tested here.
"""

import json
import os
import sys
import tempfile
import pytest

# Import the pure functions from validate_pipeline
# These must be importable without psycopg2 connecting to any DB
from validate_pipeline import evaluate_assertions, load_config


# ---------------------------------------------------------------------------
# evaluate_assertions — {min} assertions
# ---------------------------------------------------------------------------

class TestMinAssertion:
    def test_min_1_pass_with_3_officials(self):
        """Tier has 3 officials vs {min:1} -> PASS."""
        found = {"city": 3}
        assertions = {"city": {"min": 1}}
        result = evaluate_assertions(found, assertions)
        assert result["city"] is True

    def test_min_5_fail_with_3_officials(self):
        """Tier has 3 officials vs {min:5} -> FAIL."""
        found = {"city": 3}
        assertions = {"city": {"min": 5}}
        result = evaluate_assertions(found, assertions)
        assert result["city"] is False

    def test_min_1_pass_with_1_official(self):
        """Tier has exactly 1 official vs {min:1} -> PASS."""
        found = {"county": 1}
        assertions = {"county": {"min": 1}}
        result = evaluate_assertions(found, assertions)
        assert result["county"] is True

    def test_min_1_fail_with_0_officials(self):
        """Tier has 0 officials vs {min:1} -> FAIL."""
        found = {"city": 0}
        assertions = {"city": {"min": 1}}
        result = evaluate_assertions(found, assertions)
        assert result["city"] is False

    def test_missing_tier_defaults_to_0_count(self):
        """Tier not in found dict treated as 0 count — {min:1} fails."""
        found = {}
        assertions = {"school": {"min": 1}}
        result = evaluate_assertions(found, assertions)
        assert result["school"] is False


# ---------------------------------------------------------------------------
# evaluate_assertions — {max} assertions
# ---------------------------------------------------------------------------

class TestMaxAssertion:
    def test_max_3_pass_with_2_officials(self):
        """Tier has 2 officials vs {max:3} -> PASS."""
        found = {"state_senate": 2}
        assertions = {"state_senate": {"max": 3}}
        result = evaluate_assertions(found, assertions)
        assert result["state_senate"] is True

    def test_max_3_fail_with_4_officials(self):
        """Tier has 4 officials vs {max:3} -> FAIL."""
        found = {"state_senate": 4}
        assertions = {"state_senate": {"max": 3}}
        result = evaluate_assertions(found, assertions)
        assert result["state_senate"] is False

    def test_max_3_pass_with_3_officials(self):
        """Tier has exactly 3 officials vs {max:3} -> PASS (inclusive)."""
        found = {"state_senate": 3}
        assertions = {"state_senate": {"max": 3}}
        result = evaluate_assertions(found, assertions)
        assert result["state_senate"] is True


# ---------------------------------------------------------------------------
# evaluate_assertions — {min, max} range assertions
# ---------------------------------------------------------------------------

class TestRangeAssertion:
    def test_range_2_3_pass_with_2(self):
        """Tier has 2 officials vs {min:2, max:3} -> PASS."""
        found = {"state_senate": 2}
        assertions = {"state_senate": {"min": 2, "max": 3}}
        result = evaluate_assertions(found, assertions)
        assert result["state_senate"] is True

    def test_range_2_3_pass_with_3(self):
        """Tier has 3 officials vs {min:2, max:3} -> PASS."""
        found = {"state_senate": 3}
        assertions = {"state_senate": {"min": 2, "max": 3}}
        result = evaluate_assertions(found, assertions)
        assert result["state_senate"] is True

    def test_range_2_3_fail_with_4(self):
        """Tier has 4 officials vs {min:2, max:3} -> FAIL (exceeds max)."""
        found = {"state_senate": 4}
        assertions = {"state_senate": {"min": 2, "max": 3}}
        result = evaluate_assertions(found, assertions)
        assert result["state_senate"] is False

    def test_range_2_3_fail_with_1(self):
        """Tier has 1 official vs {min:2, max:3} -> FAIL (below min)."""
        found = {"state_senate": 1}
        assertions = {"state_senate": {"min": 2, "max": 3}}
        result = evaluate_assertions(found, assertions)
        assert result["state_senate"] is False


# ---------------------------------------------------------------------------
# evaluate_assertions — {exact} assertions
# ---------------------------------------------------------------------------

class TestExactAssertion:
    def test_exact_0_pass_with_0_officials(self):
        """Gap-city case: tier has 0 officials vs {exact:0} -> PASS."""
        found = {"city": 0}
        assertions = {"city": {"exact": 0}}
        result = evaluate_assertions(found, assertions)
        assert result["city"] is True

    def test_exact_0_fail_with_1_official(self):
        """Gap-city case: tier has 1 official vs {exact:0} -> FAIL."""
        found = {"city": 1}
        assertions = {"city": {"exact": 0}}
        result = evaluate_assertions(found, assertions)
        assert result["city"] is False

    def test_exact_1_pass_with_1_official(self):
        """{exact:1} with exactly 1 official -> PASS."""
        found = {"state_board": 1}
        assertions = {"state_board": {"exact": 1}}
        result = evaluate_assertions(found, assertions)
        assert result["state_board"] is True

    def test_exact_1_fail_with_2_officials(self):
        """{exact:1} with 2 officials -> FAIL."""
        found = {"state_board": 2}
        assertions = {"state_board": {"exact": 1}}
        result = evaluate_assertions(found, assertions)
        assert result["state_board"] is False

    def test_exact_0_missing_tier_treated_as_0(self):
        """Tier not in found dict treated as 0 — {exact:0} passes."""
        found = {}
        assertions = {"county": {"exact": 0}}
        result = evaluate_assertions(found, assertions)
        assert result["county"] is True


# ---------------------------------------------------------------------------
# evaluate_assertions — {expect: true} tribal_land assertions
# ---------------------------------------------------------------------------

class TestExpectAssertion:
    def test_expect_true_pass_when_tribal_land_true(self):
        """{expect:true} for tribal_land -> PASS when tribal_land count >= 1."""
        # The tribal_land key in found carries the X0004 auxiliary count (>=1 means covered)
        found = {"tribal_land": 1}
        assertions = {"tribal_land": {"expect": True}}
        result = evaluate_assertions(found, assertions)
        assert result["tribal_land"] is True

    def test_expect_true_fail_when_tribal_land_0(self):
        """{expect:true} for tribal_land -> FAIL when X0004 count is 0."""
        found = {"tribal_land": 0}
        assertions = {"tribal_land": {"expect": True}}
        result = evaluate_assertions(found, assertions)
        assert result["tribal_land"] is False

    def test_expect_true_fail_when_tribal_land_missing(self):
        """{expect:true} fails when tribal_land not in found (treated as 0)."""
        found = {}
        assertions = {"tribal_land": {"expect": True}}
        result = evaluate_assertions(found, assertions)
        assert result["tribal_land"] is False


# ---------------------------------------------------------------------------
# evaluate_assertions — superset semantics (tiers NOT in assertions ignored)
# ---------------------------------------------------------------------------

class TestSupersetsSemantics:
    def test_extra_tier_in_found_does_not_cause_fail(self):
        """CA superset semantics: tiers found but NOT in assertions are ignored."""
        found = {"federal": 3, "state_senate": 2, "judicial": 5}  # judicial is extra
        assertions = {"federal": {"min": 1}, "state_senate": {"min": 1}}
        result = evaluate_assertions(found, assertions)
        # Only federal and state_senate are evaluated; judicial is not in result
        assert result["federal"] is True
        assert result["state_senate"] is True
        assert "judicial" not in result

    def test_only_asserted_tiers_evaluated(self):
        """evaluate_assertions returns results only for tiers in assertions dict."""
        found = {"city": 5, "county": 3, "school": 7}
        assertions = {"city": {"min": 1}}
        result = evaluate_assertions(found, assertions)
        assert len(result) == 1
        assert "county" not in result
        assert "school" not in result


# ---------------------------------------------------------------------------
# evaluate_assertions — malformed assertion raises error
# ---------------------------------------------------------------------------

class TestMalformedAssertion:
    def test_unknown_key_raises_error(self):
        """Malformed assertion with unknown key raises ValueError (not silent pass)."""
        found = {"city": 3}
        assertions = {"city": {"bogus_key": 99}}
        with pytest.raises((ValueError, KeyError)):
            evaluate_assertions(found, assertions)


# ---------------------------------------------------------------------------
# load_config — JSON config loading
# ---------------------------------------------------------------------------

class TestLoadConfig:
    def test_load_ca_config(self):
        """load_config returns config with state=CA and 16 addresses."""
        scripts_dir = os.path.dirname(os.path.abspath(__file__))
        config = load_config("CA", scripts_dir)
        assert config["state"] == "CA"
        assert config["fips"] == "06"
        assert len(config["addresses"]) == 16

    def test_load_ut_config(self):
        """load_config returns config with state=UT and 10 addresses."""
        scripts_dir = os.path.dirname(os.path.abspath(__file__))
        config = load_config("UT", scripts_dir)
        assert config["state"] == "UT"
        assert config["fips"] == "49"
        assert len(config["addresses"]) == 10

    def test_load_unknown_state_raises_error(self):
        """load_config raises FileNotFoundError or SystemExit for unknown state."""
        scripts_dir = os.path.dirname(os.path.abspath(__file__))
        with pytest.raises((FileNotFoundError, SystemExit)):
            load_config("ZZ", scripts_dir)

    def test_ca_config_each_address_has_assertions(self):
        """Every CA address has at least one assertion."""
        scripts_dir = os.path.dirname(os.path.abspath(__file__))
        config = load_config("CA", scripts_dir)
        for addr in config["addresses"]:
            assert "assertions" in addr, f"Missing assertions on {addr['label']}"
            assert len(addr["assertions"]) > 0

    def test_ut_config_tribal_address_has_expect_true(self):
        """UT Fort Duchesne address has tribal_land: {expect: true}."""
        scripts_dir = os.path.dirname(os.path.abspath(__file__))
        config = load_config("UT", scripts_dir)
        tribal = next(a for a in config["addresses"] if "Duchesne" in a["label"])
        assert tribal["assertions"].get("tribal_land") == {"expect": True}

    def test_ut_config_gap_city_has_exact_0(self):
        """UT Fillmore address has county: {exact: 0} and city: {exact: 0}."""
        scripts_dir = os.path.dirname(os.path.abspath(__file__))
        config = load_config("UT", scripts_dir)
        fillmore = next(a for a in config["addresses"] if "Fillmore" in a["label"])
        assert fillmore["assertions"]["county"] == {"exact": 0}
        assert fillmore["assertions"]["city"] == {"exact": 0}

    def test_ut_config_lat_lng_match_candidates_doc(self):
        """SLC Capitol lat/lng matches 134-ut-address-candidates.md: 40.761, -111.891."""
        scripts_dir = os.path.dirname(os.path.abspath(__file__))
        config = load_config("UT", scripts_dir)
        slc = next(a for a in config["addresses"] if "451 S State" in a["label"])
        assert slc["lat"] == 40.761
        assert slc["lng"] == -111.891

    def test_with_temp_config(self):
        """load_config works with arbitrary state code given a matching JSON file."""
        with tempfile.TemporaryDirectory() as tmpdir:
            dummy = {
                "state": "XX",
                "fips": "00",
                "description": "test",
                "addresses": [
                    {
                        "label": "Test addr",
                        "lat": 0.0,
                        "lng": 0.0,
                        "notes": "test",
                        "assertions": {"city": {"min": 1}}
                    }
                ]
            }
            path = os.path.join(tmpdir, "validate-addresses-xx.json")
            with open(path, "w") as f:
                json.dump(dummy, f)
            config = load_config("XX", tmpdir)
            assert config["state"] == "XX"
            assert len(config["addresses"]) == 1
