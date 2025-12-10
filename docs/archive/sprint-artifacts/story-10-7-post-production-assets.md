# Story 10.7: Post-Production Asset Insertion

Status: drafted

## Story

As a User,
I want the object details to have beautiful and accurate images,
so that the app looks premium and I can visually identify celestial objects.

## Acceptance Criteria

1. **Missing Asset Identification**
   - [ ] Audit the current catalog (Stars, Planets, DSOs) to identify objects missing specific images.
   - [ ] Generate a list of required assets.

2. **Asset Sourcing & Preparation**
   - [ ] Source high-quality images for identified objects (User/Designer responsibility).
   - [ ] Optimize images for mobile (WebP/JPG, appropriate resolution).
   - [ ] Ensure all images are license-compliant (e.g., NASA, Creative Commons).

3. **Asset Integration**
   - [ ] Add images to `assets/img/catalog/` (or similar structure).
   - [ ] Update `CatalogRepository` or JSON data files to map objects to their new image paths.
   - [ ] Verify images load correctly in `ObjectDetailScreen`.

## Tasks / Subtasks

- [ ] Audit Catalog (AC: 1)
  - [ ] Run the app and browse the catalog.
  - [ ] Check `CatalogRepositoryImpl` for placeholder logic.
  - [ ] Create a checklist of missing images (e.g., "Andromeda Galaxy", "Orion Nebula", "Mars").

- [ ] Prepare Assets (AC: 2)
  - [ ] **Interactive:** Ask user to provide/approve the image collection.
  - [ ] Rename files to snake_case (e.g., `andromeda_galaxy.jpg`).
  - [ ] Compress images using Squoosh or similar tools.

- [ ] Integrate Assets (AC: 3)
  - [ ] Move files to `assets/img/`.
  - [ ] Update `pubspec.yaml` if adding new asset directories.
  - [ ] Update `lib/features/catalog/data/repositories/catalog_repository_impl.dart` (or data source) to use the new assets.

- [ ] Verification (AC: 3)
  - [ ] Launch app.
  - [ ] Navigate to details of updated objects.
  - [ ] Confirm images appear and look good.

## Dev Notes

- **Strategy:** Since the catalog might be hardcoded or programmatic, we might need to add a `Map<String, String> imageAssets` lookup table or update the entity model if it doesn't support custom images yet.
- **Fallbacks:** Ensure a beautiful fallback (or the generated gradient) is still used if an image fails to load.

### Project Structure Notes

- `assets/img/catalog/` (New directory recommended).
- `lib/features/catalog/data/` (Data updates).

### References

- [Source: User Request]
- [NASA Image Gallery](https://www.nasa.gov/multimedia/imagegallery/index.html)

## Dev Agent Record

### Context Reference

<!-- Path(s) to story context XML will be added here by context workflow -->

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

### Completion Notes List

### File List
