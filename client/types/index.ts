export type ProgrammingLanguage =
  | "swift"
  | "python"
  | "javascript"
  | "typescript"
  | "java"
  | "kotlin"
  | "cpp"
  | "c"
  | "rust"
  | "go"
  | "ruby"
  | "php"
  | "bash"
  | "shell"
  | "sql"
  | "html"
  | "css"
  | "scala"
  | "haskell"
  | "lua"
  | "perl"
  | "r"
  | "dart"
  | "elixir";

export const PROGRAMMING_LANGUAGES: { value: ProgrammingLanguage; label: string }[] = [
  { value: "swift", label: "Swift" },
  { value: "python", label: "Python" },
  { value: "javascript", label: "JavaScript" },
  { value: "typescript", label: "TypeScript" },
  { value: "java", label: "Java" },
  { value: "kotlin", label: "Kotlin" },
  { value: "cpp", label: "C++" },
  { value: "c", label: "C" },
  { value: "rust", label: "Rust" },
  { value: "go", label: "Go" },
  { value: "ruby", label: "Ruby" },
  { value: "php", label: "PHP" },
  { value: "bash", label: "Bash" },
  { value: "shell", label: "Shell" },
  { value: "sql", label: "SQL" },
  { value: "html", label: "HTML" },
  { value: "css", label: "CSS" },
  { value: "scala", label: "Scala" },
  { value: "haskell", label: "Haskell" },
  { value: "lua", label: "Lua" },
  { value: "perl", label: "Perl" },
  { value: "r", label: "R" },
  { value: "dart", label: "Dart" },
  { value: "elixir", label: "Elixir" },
];

export type DifficultyLevel = "easy" | "medium" | "hard" | "expert";

export const DIFFICULTY_LEVELS: { value: DifficultyLevel; label: string }[] = [
  { value: "easy", label: "Easy" },
  { value: "medium", label: "Medium" },
  { value: "hard", label: "Hard" },
  { value: "expert", label: "Expert" },
];

export type TaskStatus =
  | "pending"
  | "inProgress"
  | "completed"
  | "failed"
  | "cancelled";

export interface CodingTask {
  id: string;
  title: string;
  description: string;
  language: ProgrammingLanguage;
  difficulty: DifficultyLevel;
  status: TaskStatus;
  createdAt: number;
  completedAt?: number;
}

export interface SystemMetrics {
  tasksProcessed: number;
  tasksInQueue: number;
  activeAgents: number;
  averageTaskTime: number;
  improvementSuccessRate: number;
  uptime: number;
}

export type LogLevel =
  | "trace"
  | "debug"
  | "info"
  | "notice"
  | "warning"
  | "error"
  | "critical";

export interface LogEntry {
  id: string;
  level: LogLevel;
  message: string;
  timestamp: number;
}

export function getStatusColor(status: TaskStatus): string {
  switch (status) {
    case "pending":
      return "#FF9F0A";
    case "inProgress":
      return "#0066FF";
    case "completed":
      return "#34C759";
    case "failed":
      return "#FF453A";
    case "cancelled":
      return "#8E8E93";
    default:
      return "#8E8E93";
  }
}

export function getLogLevelColor(level: LogLevel): string {
  switch (level) {
    case "trace":
      return "#8E8E93";
    case "debug":
      return "#AF52DE";
    case "info":
      return "#0066FF";
    case "notice":
      return "#34C759";
    case "warning":
      return "#FF9F0A";
    case "error":
      return "#FF453A";
    case "critical":
      return "#FF453A";
    default:
      return "#8E8E93";
  }
}

export function formatTimeInterval(seconds: number): string {
  if (seconds < 1) {
    return `${Math.round(seconds * 1000)}ms`;
  } else if (seconds < 60) {
    return `${seconds.toFixed(1)}s`;
  } else if (seconds < 3600) {
    return `${(seconds / 60).toFixed(1)}m`;
  } else {
    return `${(seconds / 3600).toFixed(1)}h`;
  }
}

export function generateId(): string {
  return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
}
