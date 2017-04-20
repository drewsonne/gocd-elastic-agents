variable "gocd_registries" {
  type = "list"
  default = [
    "agent",
    "python-agent",
    "chroot",
    "packer"
  ]
}

resource "aws_ecr_repository" "docker-registry" {
  count = "${length(var.gocd_registries)}"
  name = "${var.environment}-gocd-agent-${element(var.gocd_registries, count.index)}"
}