# PM Order Application — Release Notes
**Date:** 20.11.2026

---

## Overview

This update resolves a series of issues discovered during testing of the PM Order maintenance screen. Users can now reliably add, change, and delete multiple components, operations, and partners in a single save. Clear error messages have also been introduced to guide users when an unsupported combination of actions is attempted.

---

## Bugs Fixed

### 1. Adding multiple components at once now works

**Before:** When a user added two or more new component lines and saved, only the last one was saved to the order. The first lines were silently lost.

**After:** All added component lines are saved correctly in one save.

---

### 2. Deleting multiple components at once now works

**Before:** When a user selected two or more existing components and deleted them, only one was actually removed from the order.

**After:** All selected components are deleted in one save.

---

### 3. Changing a component's quantity no longer gives an error

**Before:** Editing the required quantity of an existing component caused a "unit of measure not convertible" error and the change was not saved.

**After:** Quantity and unit changes are saved correctly.

---

### 4. Adding multiple partners at once now works

**Before:** Pressing the Add Partner button more than once before saving caused a system crash on the second press.

**After:** Multiple partners can be added and saved in one operation without errors.

---

### 5. Deleting multiple partners at once now works

**Before:** Selecting and deleting more than one partner at the same time resulted in an error and no partners were removed.

**After:** All selected partners are deleted successfully in one save.

---

### 6. Material lookup is now filtered by order plant

**Before:** When selecting a material for a component, the lookup list showed all materials in the system regardless of plant.

**After:** The material lookup now shows only materials available at the order's planning plant, reducing irrelevant results and making selection faster.

---

## New Validation Rules

The following restrictions have been introduced to prevent errors that the system cannot resolve automatically. If a rule is violated, a clear error message is shown and the save is blocked. The user must discard the draft and retry with the correct sequence.

---

### Rule 1: Cannot add and delete partners in the same save

You cannot add a new partner and delete an existing partner in the same save operation. Perform one operation, save, then open the order again for the second operation.

**Error message you will see:**
> *"Cannot add and delete partners in one save. Discard draft, then do only one operation."*

---

### Rule 2: An already-saved partner cannot be edited directly

If a partner has already been committed to the system, its fields cannot be changed by editing the row inline. To change a partner, delete the existing one and re-add it with the correct values.

**Error message you will see:**
> *"Partner already saved - changes not allowed. Discard the draft and delete/re-add the partner."*

---

### Rule 3: Only one section can be changed per save

Due to a technical constraint in SAP PM order processing, changes to two different sections (Components, Operations, Partners) cannot be saved in the same save operation. Each section must be saved separately.

For example: you cannot add a component and add a partner in the same save. Save the component first, then open the order again and add the partner.

**Error message you will see:**
> *"Only one section per save (comp/op/partner). Discard draft and save each section separately."*

---

## How to Discard a Draft

If you receive one of the above errors:

1. Click the **Discard** button at the top of the order screen (next to the "Draft" indicator).
2. Confirm when prompted.
3. The order returns to its last saved state.
4. Re-open the order and perform only one type of change, then save.
