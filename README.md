# AutonomousCoder

An AI-powered autonomous code generation and monitoring application built with React Native (Expo) and Node.js/Express.

## Features

- **AI Code Generation**: Transform natural language task descriptions into functional code
- **Multi-Language Support**: Generate code in 25+ programming languages
- **Real-time Monitoring**: Track task processing and system metrics
- **Task Management**: Create, monitor, and manage coding tasks
- **Generated Code Viewer**: View, copy, and review AI-generated code

## Prerequisites

- Node.js 18+ 
- npm or yarn
- OpenAI API key (optional - falls back to mock generation)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/Darknessownsu/AutonomousCoder.git
cd AutonomousCoder
```

2. Install dependencies:
```bash
npm install
```

3. Configure environment variables:
```bash
cp .env.example .env
# Edit .env and add your OpenAI API key
```

## Configuration

Create a `.env` file in the root directory with the following variables:

```env
OPENAI_API_KEY=your-openai-api-key-here
PORT=5000
NODE_ENV=development
```

### Getting an OpenAI API Key

1. Go to [OpenAI Platform](https://platform.openai.com/)
2. Sign up or log in to your account
3. Navigate to API Keys section
4. Create a new API key
5. Copy and paste it into your `.env` file

**Note**: If you don't configure an OpenAI API key, the system will automatically fall back to mock code generation for testing purposes.

## Running the Application

### Development Mode

Start both the server and client in development mode:

```bash
# Terminal 1 - Start the backend server
npm run server:dev

# Terminal 2 - Start the Expo development server
npm run expo:dev
```

The server will run on `http://localhost:5000` and the Expo development server will provide instructions for running on mobile/web.

### Production Mode

Build and run in production:

```bash
# Build the server
npm run server:build

# Build the Expo static files
npm run expo:static:build

# Run the production server
npm run server:prod
```

## Usage

1. **Start the System**: Open the app and click the "Start" button on the Dashboard
2. **Create a Task**: Navigate to the Tasks tab and create a new coding task by providing:
   - Task title
   - Detailed description
   - Programming language
   - Difficulty level
3. **Monitor Progress**: Watch real-time progress on the Dashboard and Monitor screens
4. **View Generated Code**: Once complete, click "View Code" on any completed task to see the AI-generated code

## Architecture

```
AutonomousCoder/
├── client/                 # React Native/Expo frontend
│   ├── components/        # Reusable UI components
│   ├── screens/          # Application screens
│   ├── navigation/       # Navigation configuration
│   ├── context/          # React Context providers
│   ├── hooks/            # Custom React hooks
│   ├── lib/              # API and utility functions
│   └── types/            # TypeScript type definitions
├── server/                # Node.js/Express backend
│   ├── lib/              # Server utilities and services
│   │   ├── ai-service.ts # AI code generation service
│   │   └── github.ts     # GitHub integration
│   ├── routes.ts         # API routes
│   └── index.ts          # Server entry point
└── shared/               # Shared types and schemas
    └── schema.ts         # Zod schemas for validation
```

## API Endpoints

### POST /api/generate-code

Generate code from a task description.

**Request:**
```json
{
  "title": "Sort Array",
  "description": "Implement quicksort algorithm",
  "language": "python",
  "difficulty": "medium"
}
```

**Response:**
```json
{
  "code": "def quicksort(arr):\n    ...",
  "explanation": "This implementation uses the quicksort algorithm...",
  "language": "python"
}
```

### GET /api/health

Health check endpoint.

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2026-01-01T20:00:00.000Z"
}
```

## Supported Languages

- Swift, Python, JavaScript, TypeScript
- Java, Kotlin, C++, C, Rust, Go
- Ruby, PHP, Bash, Shell, SQL
- HTML, CSS, Scala, Haskell
- Lua, Perl, R, Dart, Elixir

## Development Scripts

- `npm run server:dev` - Run server in development mode
- `npm run expo:dev` - Run Expo development server
- `npm run lint` - Run ESLint
- `npm run lint:fix` - Fix ESLint issues
- `npm run check:types` - Type check with TypeScript
- `npm run format` - Format code with Prettier
- `npm run check:format` - Check code formatting

## Technologies Used

- **Frontend**: React Native, Expo, React Navigation, TypeScript
- **Backend**: Node.js, Express, TypeScript
- **AI**: OpenAI GPT-4
- **State Management**: React Context + AsyncStorage
- **Validation**: Zod
- **Styling**: React Native StyleSheet

## Security

- All user inputs are sanitized and validated
- API endpoints use Zod schema validation
- Environment variables for sensitive configuration
- CORS protection on API endpoints

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details

## Support

For issues, questions, or contributions, please visit the [GitHub repository](https://github.com/Darknessownsu/AutonomousCoder).
