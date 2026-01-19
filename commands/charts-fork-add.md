# Add Chart Fork

Fork an upstream Helm chart repository and add it as a git submodule.

## Arguments

- `<url>` - Git URL of the forked repository (required)

## Instructions

1. **Parse the URL**: Extract the chart name from the repository URL
   - Example: `https://github.com/user/cert-manager` -> `cert-manager`

2. **Validate**: Check that:
   - The URL is a valid git repository
   - The fork doesn't already exist in `forks/`
   - The submodule isn't already configured

3. **Add Submodule**: Add the fork as a git submodule
   ```bash
   git submodule add <url> forks/<chart-name>
   ```

4. **Initialize Tracking**: Set up upstream remote for sync
   ```bash
   cd forks/<chart-name>
   # If upstream URL provided, add it
   git remote add upstream <upstream-url>
   ```

5. **Create Values Directory**: Prepare the values structure
   ```bash
   mkdir -p configs/values/<chart-name>
   ```

6. **Report Success**: Show next steps

## Example Usage

```
/charts-fork-add https://github.com/MisterGrinvalds/cert-manager
```

## Output

On success:
```
Added fork: cert-manager
  Location: forks/cert-manager
  Remote: origin -> https://github.com/MisterGrinvalds/cert-manager

Next steps:
  1. Add upstream remote: cd forks/cert-manager && git remote add upstream <upstream-url>
  2. Create context: /charts-context-create local
  3. Create values: /charts-values-create cert-manager local
```

## Error Handling

- **Fork exists**: "Fork 'cert-manager' already exists. Use /charts-fork-sync to update."
- **Invalid URL**: "Invalid git URL. Please provide a valid repository URL."
- **Clone failed**: "Failed to clone repository. Check URL and permissions."
