import json
import tempfile
import unittest
from pathlib import Path

from onboard_application import generate, read_registration, validate_registration


ROOT = Path(__file__).resolve().parents[1]
SAMPLE = ROOT / "applications" / "registrations" / "demo-api.json"


class OnboardApplicationTests(unittest.TestCase):
    def test_sample_registration_is_valid(self) -> None:
        validate_registration(read_registration(SAMPLE))

    def test_latest_image_is_rejected(self) -> None:
        registration = read_registration(SAMPLE)
        registration["image"] = "registry.example/demo-api:latest"

        with self.assertRaisesRegex(ValueError, "must not use the latest tag"):
            validate_registration(registration)

    def test_generation_matches_committed_sample(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            output = Path(temporary_directory) / "demo-api"
            generate(SAMPLE, output, check=False)
            generate(SAMPLE, ROOT / "applications" / "onboarded" / "demo-api", check=True)
            self.assertEqual(
                sorted(path.name for path in output.glob("*.yaml")),
                sorted(path.name for path in (ROOT / "applications" / "onboarded" / "demo-api").glob("*.yaml")),
            )

    def test_missing_ingress_host_is_rejected(self) -> None:
        registration = read_registration(SAMPLE)
        registration["ingress"] = {"enabled": True}

        with self.assertRaisesRegex(ValueError, "ingress.host"):
            validate_registration(registration)


if __name__ == "__main__":
    unittest.main()
