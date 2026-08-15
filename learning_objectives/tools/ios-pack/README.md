# SFA iOS Packaging Tool

This tool packages the local `mobile-sfa-ios` repo without committing generated
artifacts or signing secrets to Harness.

Use the stable wrapper:

```bash
scripts/sfa-ios-pack.sh --check
scripts/sfa-ios-pack.sh --configuration Debug --method Development --upload none --notes "SIT validation"
```

Set `SFA_REPO_MOBILE_SFA_IOS` in ignored `config/repos.local.sh`. The legacy
`SFA_REPO_IOS_SFA` variable is accepted as a fallback during migration.

Generated files go under `artifacts/ios-pack/`, which is ignored by Git.
