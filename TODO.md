# Mileager TODO

## Location Service Improvements

### Critical Issues
- [ ] Fix address geocoding not finding locations
  - Debug geocoding service response
  - Add error logging to see exact failure points
  - Test with various address formats
  - Consider adding address validation before geocoding attempt
  - Add retry mechanism for failed geocoding attempts

### Features & Improvements
- [ ] Add address autocomplete functionality
  - Integrate with Places API for address suggestions
  - Add validation for address components
  - Improve address format handling

- [ ] Enhance location management
  - Add ability to edit existing locations
  - Add ability to reorder locations
  - Add favorites/frequently used locations
  - Add location categories (home, work, etc.)

- [ ] Improve location UI/UX
  - Add map preview for locations
  - Add distance preview between locations
  - Add location search/filter functionality
  - Add bulk delete option

### Testing & Validation
- [ ] Add comprehensive location service tests
  - Test geocoding with various address formats
  - Test location permission scenarios
  - Test background location updates
  - Test location distance calculations

- [ ] Add error handling improvements
  - Better error messages for users
  - Better error logging for debugging
  - Add fallback options for failed operations
  - Add network connectivity handling

## Next Steps
1. Debug geocoding service
   - Add logging to LocationService
   - Test with known good addresses
   - Verify API key and permissions
   - Check response format

2. Implement address validation
   - Add input validation
   - Add address format standardization
   - Add address component validation

3. Add error recovery
   - Add retry mechanism
   - Add fallback options
   - Improve error messages 