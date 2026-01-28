# Workflow Patterns

Use these patterns when skills involve multi-step processes or conditional logic.

## Sequential Workflows

For tasks with multiple ordered steps, provide a clear process overview upfront:

```markdown
## PDF Form Filling Workflow

Follow these steps in order:

### Step 1: Analyze the PDF
- Open the PDF and identify all form fields
- Note field types (text, checkbox, dropdown, signature)
- Map field names to their purposes

### Step 2: Prepare the Data
- Gather all required information
- Validate data formats match field requirements
- Handle any missing required fields

### Step 3: Fill the Form
- Use pdftk or equivalent to populate fields
- Preserve existing formatting and structure
- Handle special characters appropriately

### Step 4: Add Signatures (if needed)
- Generate or apply signature images
- Position correctly within signature fields

### Step 5: Verify and Finalize
- Review all filled fields
- Ensure no data corruption
- Save as flattened PDF if required
```

## Conditional Workflows

For tasks that branch based on conditions, use decision trees:

```markdown
## Document Processing Workflow

First, determine the document type:

### If creating a new document:
1. Choose the appropriate template
2. Set up document metadata
3. Add content sections
4. Apply formatting

### If editing an existing document:
1. Parse the current document structure
2. Identify sections to modify
3. Make changes while preserving formatting
4. Track changes if requested

### If converting between formats:
1. Extract content from source format
2. Map structure to target format
3. Handle format-specific features
4. Validate output integrity
```

## Best Practices

1. **Keep steps atomic** - Each step should do one thing
2. **Include verification** - Add checkpoints to confirm success
3. **Handle errors** - Describe what to do when steps fail
4. **Show dependencies** - Make clear which steps depend on others
