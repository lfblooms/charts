# Add Chart Fork

Fork an upstream repository and add it as a git submodule.

## Arguments

- `<upstream-url>` - Git URL of the upstream repository (required)

## Repository Structure

Forks follow the naming convention: `forks/<Owner>.<repo>`

Example:
- Upstream: `https://github.com/Infisical/infisical`
- Fork: `https://github.com/lfblooms/Infisical.infisical`
- Submodule path: `forks/infisical`

## Instructions

1. **Parse the URL**: Extract owner and repo from the upstream URL
   - Example: `https://github.com/Infisical/infisical` -> Owner: `Infisical`, Repo: `infisical`

2. **Create Fork**: Fork to user's GitHub with naming convention
   ```bash
   gh repo fork <upstream-url> --clone=false --fork-name "<Owner>.<repo>"
   ```

3. **Add Submodule**: Add the fork as a git submodule
   ```bash
   git submodule add https://github.com/lfblooms/<Owner>.<repo>.git forks/<repo>
   ```

4. **Configure Upstream**: Set up upstream remote for sync
   ```bash
   git -C forks/<repo> remote add upstream <upstream-url>
   ```

5. **Locate Helm Charts**: Find helm charts within the repo
   ```bash
   find forks/<repo> -name "Chart.yaml" -exec dirname {} \;
   ```

6. **Create Values Directory**: Prepare the values structure for each chart
   ```bash
   mkdir -p configs/values/<chart-name>
   ```

7. **Create Makefile**: Generate `makefiles/<repo>.mk` for the fork

## Example Usage

```
/charts-fork-add https://github.com/Infisical/infisical
```

## Output

On success:
```
Forked: Infisical/infisical -> lfblooms/Infisical.infisical

Submodule added:
  Path: forks/infisical
  Origin: https://github.com/lfblooms/Infisical.infisical.git
  Upstream: https://github.com/Infisical/infisical.git

Helm charts found:
  - helm-charts/infisical-standalone-postgres
  - helm-charts/infisical-gateway

Next steps:
  1. Create makefile: makefiles/infisical.mk
  2. Create context: /charts-context-create local
  3. Create values: /charts-values-create infisical-standalone-postgres local
```

## Error Handling

- **Fork exists**: "Fork already exists at lfblooms/<Owner>.<repo>"
- **Submodule exists**: "Submodule 'forks/<repo>' already configured"
- **No charts found**: "No Helm charts found in repository"
