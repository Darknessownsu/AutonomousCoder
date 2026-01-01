# AutonomousCoder

## Overview
AutonomousCoder is a native iOS/macOS developer tool for autonomous AI code generation and monitoring. Built with React Native/Expo, it enables users to create coding tasks, monitor AI agents processing them, view system metrics, and track logs in real-time.

## Current State
Fully functional with:
- Dashboard with system status, metrics grid, and quick actions
- Tasks screen with task list and creation modal
- Monitor screen with performance metrics and agent status
- Logs screen with filterable log entries
- AsyncStorage persistence for tasks, logs, and system state
- Simulated task processing (tasks auto-process when system is running)

## Project Architecture

### Frontend (Expo/React Native)
- **client/App.tsx** - Root component with providers (AppStateProvider, QueryClientProvider, etc.)
- **client/context/AppStateContext.tsx** - Global state management with AsyncStorage persistence
- **client/navigation/** - Navigation structure (MainTabNavigator, RootStackNavigator)
- **client/screens/** - Main screens (Dashboard, Tasks, Monitor, Logs, TaskCreator)
- **client/types/index.ts** - TypeScript types and helper functions
- **client/constants/theme.ts** - Theme configuration (OLED black, electric blue accent)

### Backend (Express)
- **server/index.ts** - Express server serving static Expo files and API endpoints
- Port 5000 for backend APIs and landing page

### Key Features
- **System Start/Stop** - Toggle AI processing system
- **Task Management** - Create, view, cancel, delete coding tasks
- **Metrics Tracking** - Tasks processed, queue length, success rate, uptime
- **Log Monitoring** - Real-time logging with level-based filtering
- **Input Validation** - Sanitization of user inputs, length limits

## Design Guidelines
- OLED-optimized dark theme (#000000 background)
- Electric blue primary color (#0066FF)
- iOS 26 liquid glass interface design patterns
- Feather icons for cross-platform compatibility

## Commands
- **Start App**: `npm run server:dev && npm run expo:dev`
- Expo runs on port 8081, Express on port 5000

## Recent Changes
- January 2026: Initial implementation translated from Swift to React Native
