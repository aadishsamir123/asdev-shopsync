# Implementation Plan: Enhanced Sharing Features for ShopSync

## Overview

This plan outlines the implementation of fine-grained permission controls and link-based sharing for the ShopSync shopping list app. The current system has a simple member-based access model where all members have full edit access. The new system will introduce role-based permissions (viewer/editor) and shareable links with configurable access levels.

## Requirements

### Core Requirements

1. **Individual Permission Management**: List owners can set specific permissions (viewer/editor) for each collaborator
2. **Permission-Based UI**: The app UI must respect permissions and disable edit functionality for viewers
3. **Link-Based Sharing**: Generate shareable links with configurable access levels (view-only or edit)
4. **Link Management**: Users can create up to 5 active links per list with the ability to manage and revoke them
5. **Deep Link Handling**: Support joining lists via shared links with appropriate permission assignment

### Technical Requirements

1. Update Firestore data structure to support permissions
2. Implement permission checking throughout the app
3. Create link generation and management system
4. Add UI components for permission management
5. Implement deep link handling for shared links

## Implementation Steps

### Phase 1: Data Structure Updates

#### 1.1 Update Firestore Schema

**File**: `lib/services/firestore_service.dart` (create new service)

- Modify lists collection structure:

CURRENT STRUCTURE:

```dart
{
    'members': ['userId1', 'userId2'],
    'createdBy': 'ownerId'
}
```

NEW STRUCTURE:

```dart
{
    'members': {
        'userId1': {'role': 'editor', 'joinedAt': Timestamp},
        'userId2': {'role': 'viewer', 'joinedAt': Timestamp}
    },
    'createdBy': 'ownerId',
    'shareLinks': {
        'linkId1': {
            'id': 'linkId1',
            'accessLevel': 'editor', // 'viewer' or 'editor'
            'createdAt': Timestamp,
            'createdBy': 'userId',
            'expiresAt': Timestamp?, // Optional expiration
            'isActive': true,
            'usageCount': 0,
            'maxUsage': null // Optional usage limit
        }
    }
}
```

#### 1.2 Create Permission Constants

**File**: `lib/constants/permissions.dart` (new file)

```dart
class Permission {
static const String owner = 'owner';
static const String editor = 'editor';
static const String viewer = 'viewer';
}

class ShareLinkAccessLevel {
static const String viewer = 'viewer';
static const String editor = 'editor';
}
```

### Phase 2: Permission Service Layer

#### 2.1 Create Permission Service

**File**: `lib/services/permission_service.dart` (new file)

- Implement methods:
  - `getUserPermission(String listId, String userId)`
  - `canUserEdit(String listId, String userId)`
  - `canUserView(String listId, String userId)`
  - `isListOwner(String listId, String userId)`
  - `updateUserPermission(String listId, String userId, String permission)`

#### 2.2 Create Share Link Service

**File**: `lib/services/share_link_service.dart` (new file)

- Implement methods:
  - `generateShareLink(String listId, String accessLevel)`
  - `getActiveShareLinks(String listId)`
  - `revokeShareLink(String listId, String linkId)`
  - `joinViaShareLink(String linkToken)`
  - `validateShareLink(String linkToken)`

### Phase 3: UI Updates for Permission Management

#### 3.1 Enhanced Share Menu Screen

**File**: `lib/screens/list_options.dart` (modify existing ShareMenuScreen)

- Add permission dropdown for each member
- Add UI to manage individual permissions
- Add section for link-based sharing
- Show current permission status with visual indicators

#### 3.2 Create Share Links Management Screen

**File**: `lib/screens/share_links_screen.dart` (new file)

- Display active share links with access levels
- Create new link functionality with access level selection
- Revoke/delete link functionality
- Copy link to clipboard feature
- Link usage statistics

#### 3.3 Update Member List Display

**File**: `lib/screens/list_options.dart` (modify existing member display)

- Show role badges (Owner, Editor, Viewer) next to member names
- Add permission change dropdown for owners
- Update member removal logic to respect permissions

### Phase 4: Permission-Based UI Restrictions

#### 4.1 Update Task Management Screens

**Files to modify**:

- `lib/screens/list_view.dart`
- `lib/screens/task_details.dart`
- `lib/screens/create_task.dart`

**Changes**:

- Add permission checks before enabling edit functionality
- Hide/disable FAB for task creation for viewers
- Disable task editing, deletion, and status changes for viewers
- Show read-only UI indicators for viewers

#### 4.2 Update List Management Options

**File**: `lib/screens/list_options.dart`

**Changes**:

- Hide list management options (rename, delete, clear completed) for viewers
- Show different option sets based on user role
- Add visual indicators showing user's current permission level

#### 4.3 Create Permission Widgets

**File**: `lib/widgets/permission_widgets.dart` (new file)

- `PermissionBadge`: Display user role with appropriate styling
- `PermissionBasedWidget`: Wrapper widget that shows/hides content based on permissions
- `EditableField`: Field that becomes read-only based on permissions

### Phase 5: Deep Link Implementation

#### 5.1 Configure Deep Link Handling

**Files to modify**:

- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`
- `lib/main.dart`

**Changes**:

- Configure URL schemes for share links
- Add intent filters for Android
- Update iOS URL schemes

#### 5.2 Create Link Join Flow

**File**: `lib/screens/join_via_link_screen.dart` (new file)

- Link validation screen
- Permission level display
- Join confirmation dialog
- Error handling for invalid/expired links

#### 5.3 Update App Navigation

**File**: `lib/main.dart` and routing logic

- Handle incoming deep links
- Navigate to appropriate join flow
- Update app initialization to check for pending link joins

### Phase 6: Migration and Backward Compatibility

#### 6.1 Create Data Migration Service

**File**: `lib/services/migration_service.dart` (new file)

- Convert existing member arrays to new permission structure
- Set all existing members as 'editor' by default
- Ensure backward compatibility during transition

#### 6.2 Update Existing Share Logic

**File**: `lib/screens/list_options.dart` (modify ShareMenuScreen)

- Update `_shareList()` method to use new permission structure
- Default new members to 'editor' role
- Maintain existing email-based sharing functionality

### Phase 7: Enhanced Security and Validation

#### 7.1 Add Permission Validation

**File**: `lib/services/validation_service.dart` (new file)

- Server-side permission validation
- Rate limiting for link generation
- Input validation for permission changes

#### 7.2 Add Security Rules

**File**: `firestore.rules`

- Update Firestore security rules to enforce permissions
- Prevent unauthorized permission changes
- Validate share link operations

## Testing Strategy

### Unit Tests

**Files to create**:

- `test/services/permission_service_test.dart`
- `test/services/share_link_service_test.dart`
- `test/widgets/permission_widgets_test.dart`

**Test Coverage**:

- Permission calculation logic
- Share link generation and validation
- UI permission enforcement
- Data migration logic

### Integration Tests

**Files to create**:

- `test/integration/permission_flow_test.dart`
- `test/integration/share_link_flow_test.dart`

**Test Scenarios**:

- Complete permission management workflow
- Share link creation and usage
- Deep link handling
- Cross-platform compatibility

### Manual Testing Checklist

- [ ] Owner can change member permissions
- [ ] Viewers cannot edit tasks or lists
- [ ] Editors can perform all edit operations
- [ ] Share links work correctly on both platforms
- [ ] Deep links navigate properly
- [ ] Permission changes reflect immediately in UI
- [ ] Link revocation works as expected
- [ ] Maximum link limit is enforced

## Implementation Timeline

### Week 1: Foundation

- Data structure updates
- Permission and share link services
- Basic migration logic

### Week 2: Core UI Updates

- Enhanced share menu
- Permission management UI
- Share links management screen

### Week 3: Permission Enforcement

- Update all edit flows with permission checks
- Implement permission-based UI restrictions
- Create permission widgets

### Week 4: Deep Links and Polish

- Deep link configuration and handling
- Join via link flow
- Testing and bug fixes

### Week 5: Testing and Deployment

- Comprehensive testing
- Performance optimization
- Documentation updates
- Gradual rollout strategy

## Technical Considerations

### Performance

- Cache permission data locally to avoid repeated Firestore queries
- Implement efficient permission checking with minimal database calls
- Use Firestore compound indexes for permission queries

### User Experience

- Progressive disclosure for advanced sharing features
- Clear visual indicators for permission levels
- Intuitive permission management interface
- Smooth onboarding for link-based sharing

### Security

- Secure share link generation with proper entropy
- Rate limiting for link creation
- Audit trail for permission changes
- Proper validation of all permission operations

### Scalability

- Design for future permission types
- Extensible link sharing system
- Efficient data structure for large member lists
- Consideration for team/organization
