# AutonomousCoder Design Guidelines

## Architecture Decisions

### Authentication
**Required** - This developer tool needs cloud sync for code projects and AI conversation history.

**Implementation:**
- Primary: Apple Sign-In (iOS/macOS requirement)
- Secondary: GitHub OAuth (developer-appropriate)
- Include privacy policy & terms of service links
- Account screen with: logout confirmation, nested account deletion under Settings > Account > Delete

### Navigation Structure
**Tab Navigation** (4 tabs + FAB)
- **Home**: Active coding sessions & recent projects
- **Projects**: Browse all saved projects/workspaces  
- **History**: AI conversation & code generation history
- **Settings**: Account, preferences, API configuration

**Core Action**: Floating Action Button for "New Coding Session"

### Screen Specifications

#### Home Screen
- **Purpose**: Quick access to active work and create new sessions
- **Layout:**
  - Transparent header with "AutonomousCoder" title, right button for notifications
  - Safe area: top = headerHeight + Spacing.xl, bottom = tabBarHeight + Spacing.xl
  - Scrollable main content with sections: Active Sessions, Recent Projects
- **Components:** Project cards, empty state with FAB prompt

#### New Session Screen (Modal)
- **Purpose**: Configure and start an AI coding session
- **Layout:**
  - Default navigation header with "Cancel" (left) and "Start" (right)
  - Scrollable form with fields: Project name, language/framework selectors, description
  - Safe area: top = Spacing.xl, bottom = insets.bottom + Spacing.xl
- **Components:** Text inputs, dropdown pickers, segmented controls

#### Active Coding Screen
- **Purpose**: Real-time interaction with AI coder
- **Layout:**
  - Transparent header with project name, right button for "Options" menu
  - Split view: Code editor (top 60%), AI chat interface (bottom 40%)
  - Safe area: top = headerHeight + Spacing.xl, bottom = tabBarHeight + Spacing.xl
- **Components:** Syntax-highlighted code viewer, message bubbles, input field with send button

#### Projects Screen
- **Purpose**: Browse and manage all projects
- **Layout:**
  - Default header with "Projects" title, search bar, right button for filter/sort
  - List view with project cards showing: name, language, last modified, file count
  - Safe area: top = Spacing.xl, bottom = tabBarHeight + Spacing.xl
- **Components:** Search bar, filterable list, swipe actions (archive, delete)

#### History Screen
- **Purpose**: Review past AI interactions and generated code
- **Layout:**
  - Default header with "History" title, search bar
  - Chronological list of conversation sessions
  - Safe area: top = Spacing.xl, bottom = tabBarHeight + Spacing.xl
- **Components:** Grouped list by date, preview snippets

#### Settings Screen
- **Purpose**: Configure app preferences and account
- **Layout:**
  - Default header with "Settings" title
  - Scrollable grouped list
  - Safe area: top = Spacing.xl, bottom = tabBarHeight + Spacing.xl
- **Sections:** Account, Editor Preferences (theme, font size), API Keys, Notifications, About

## Design System

### Color Palette
**Developer-focused monochrome with accent:**
- Primary: Electric Blue (#0066FF) - for CTAs and highlights
- Background: Pure Black (#000000) for OLED optimization
- Surface: Dark Gray (#1C1C1E) - cards and elevated elements
- Border: Subtle Gray (#2C2C2E)
- Text Primary: White (#FFFFFF)
- Text Secondary: Light Gray (#AEAEB2)
- Success: Green (#34C759) - successful compilation
- Error: Red (#FF453A) - code errors
- Warning: Orange (#FF9F0A)

### Typography
**System font (SF Pro) for native feel:**
- Large Title: 34pt Bold (screen headers)
- Title: 22pt Semibold (section headers)
- Headline: 17pt Semibold (card titles)
- Body: 17pt Regular (primary content)
- Code: SF Mono 14pt (code snippets)
- Caption: 12pt Regular (metadata)

### Visual Design
**Icons:** Use SF Symbols for navigation and actions (chevron.left.forwardslash.chevron.right for code, clock.arrow.circlepath for history, gear for settings)

**Touchable Feedback:**
- List items: Subtle highlight (#2C2C2E) on press
- Buttons: Scale transform (0.96) + opacity (0.8)
- FAB: Drop shadow with shadowOffset {width: 0, height: 2}, shadowOpacity: 0.10, shadowRadius: 2

**Cards:**
- Corner radius: 12pt
- Background: Surface color (#1C1C1E)
- No drop shadow (flat design for developer aesthetic)

**Code Display:**
- Syntax highlighting with VSCode Dark+ theme colors
- Line numbers in caption text color
- Monospace font (SF Mono)

### Critical Assets
1. **App Icon**: Abstract geometric representation of autonomous coding (interlocking brackets/braces)
2. **Empty State Illustrations** (minimalist line art):
   - No active sessions: Floating code snippets forming a circuit
   - No projects: Empty folder with sparkles
   - No history: Empty timeline

### Accessibility
- Minimum touch target: 44x44pt
- Color contrast ratio: 7:1 for text, 3:1 for UI elements
- VoiceOver labels for all interactive elements
- Dynamic Type support for all text
- Reduce Motion: Disable scale transforms, keep opacity changes