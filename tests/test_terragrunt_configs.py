"""
Lightweight assertions for critical Terragrunt stacks.

The tests focus on flags and settings that are easy to regress when editing
inputs in each stack. They parse the raw HCL as text to avoid introducing
extra dependencies while still providing fast feedback in CI.
"""

from pathlib import Path
import unittest


def read_file(path: str) -> str:
    return Path(path).read_text(encoding="utf-8")


class TerragruntConfigTests(unittest.TestCase):
    def test_vpc_stacks_enable_network_baselines(self) -> None:
        expectations = {
            "dev": {
                "flow_log_type": '"REJECT"',
                "extra_flags": [],
            },
            "stg": {
                "flow_log_type": '"ALL"',
                "extra_flags": [
                    "manage_default_security_group  = true",
                ],
            },
        }

        for env, expectation in expectations.items():
            with self.subTest(stack=f"{env}-vpc"):
                content = read_file(f"live/{env}/us-east-1/network/vpc/terragrunt.hcl")
                self.assertIn("enable_nat_gateway", content)
                self.assertIn("enable_flow_log                    = true", content)
                self.assertIn(
                    f'flow_log_traffic_type              = {expectation["flow_log_type"]}',
                    content,
                )
                for flag in expectation["extra_flags"]:
                    self.assertIn(flag, content)

    def test_eks_clusters_keep_essential_security_flags(self) -> None:
        content_dev = read_file("live/dev/us-east-1/eks/cluster/terragrunt.hcl")
        content_stg = read_file("live/stg/us-east-1/eks/cluster/terragrunt.hcl")

        def irsa_flag_is_true(body: str) -> bool:
            for line in body.splitlines():
                stripped = line.strip()
                if stripped.startswith("enable_irsa"):
                    return stripped.endswith("= true")
            return False

        for env, content in {"dev": content_dev, "stg": content_stg}.items():
            with self.subTest(stack=f"{env}-eks"):
                self.assertTrue(irsa_flag_is_true(content))
                self.assertIn("cluster_addons", content)
                self.assertIn('coredns    = { version = "v1.11.1-eksbuild.1" }', content)
                self.assertIn(
                    'managed_node_groups = {\n    system = {', content
                )
                self.assertIn("enabled_log_types = [", content)
                self.assertIn('"api"', content)
                self.assertIn('"audit"', content)

        with self.subTest(stack="stg-eks"):
            self.assertIn("cluster_endpoint_private_access = true", content_stg)
            self.assertIn("cluster_endpoint_public_access  = false", content_stg)
            self.assertIn("cluster_encryption_config", content_stg)
            self.assertIn("authentication_mode = \"API_AND_CONFIG_MAP\"", content_stg)

    def test_karpenter_stacks_enable_operational_handlers(self) -> None:
        content_dev = read_file("live/dev/us-east-1/eks/karpenter/terragrunt.hcl")
        content_stg = read_file("live/stg/us-east-1/eks/karpenter/terragrunt.hcl")

        for env, content in {"dev": content_dev, "stg": content_stg}.items():
            with self.subTest(stack=f"{env}-karpenter"):
                self.assertIn("enable_spot_interruption_handler = true", content)
                self.assertIn("create_instance_profile          = true", content)
                self.assertIn("create_controller        = true", content)

        with self.subTest(stack="stg-karpenter"):
            self.assertIn("consolidation            = { enabled = true }", content_stg)
            self.assertIn("drift                    = { enabled = true }", content_stg)

    def test_atlantis_irsa_roles_limit_trust_relationship(self) -> None:
        content_dev = read_file("live/dev/us-east-1/iam/atlantis/terragrunt.hcl")
        content_stg = read_file("live/stg/us-east-1/iam/atlantis/terragrunt.hcl")

        for env, content in {"dev": content_dev, "stg": content_stg}.items():
            with self.subTest(stack=f"{env}-atlantis-irsa"):
                self.assertIn("sts:AssumeRoleWithWebIdentity", content)
                self.assertIn("system:serviceaccount:atlantis:atlantis", content)
                self.assertIn("AssumeExecutionRole", content)

    def test_terraform_execution_roles_remain_high_privilege(self) -> None:
        content_dev = read_file("live/dev/us-east-1/iam/terraform-exec/terragrunt.hcl")
        content_stg = read_file("live/stg/us-east-1/iam/terraform-exec/terragrunt.hcl")

        for env, content in {"dev": content_dev, "stg": content_stg}.items():
            with self.subTest(stack=f"{env}-terraform-exec"):
                self.assertIn("assume_role_policy_statements", content)
                self.assertIn("TerraformProvisioning", content)
                self.assertIn("max_session_duration = 14400", content)


if __name__ == "__main__":
    unittest.main()
