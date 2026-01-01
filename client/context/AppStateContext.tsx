import React, {
  createContext,
  useContext,
  useState,
  useEffect,
  useCallback,
  useRef,
  ReactNode,
} from "react";
import AsyncStorage from "@react-native-async-storage/async-storage";
import {
  CodingTask,
  SystemMetrics,
  LogEntry,
  TaskStatus,
  generateId,
  ProgrammingLanguage,
  DifficultyLevel,
} from "@/types";

const STORAGE_KEYS = {
  TASKS: "@autonomouscoder/tasks",
  LOGS: "@autonomouscoder/logs",
  SYSTEM_STATE: "@autonomouscoder/system_state",
};

interface AppState {
  isRunning: boolean;
  tasks: CodingTask[];
  logs: LogEntry[];
  systemMetrics: SystemMetrics;
  startSystem: () => Promise<void>;
  stopSystem: () => Promise<void>;
  addTask: (
    title: string,
    description: string,
    language: ProgrammingLanguage,
    difficulty: DifficultyLevel,
  ) => Promise<void>;
  updateTaskStatus: (taskId: string, status: TaskStatus) => Promise<void>;
  deleteTask: (taskId: string) => Promise<void>;
  addLog: (level: LogEntry["level"], message: string) => void;
  clearLogs: () => Promise<void>;
  isLoading: boolean;
}

const defaultMetrics: SystemMetrics = {
  tasksProcessed: 0,
  tasksInQueue: 0,
  activeAgents: 0,
  averageTaskTime: 0,
  improvementSuccessRate: 0,
  uptime: 0,
};

const AppStateContext = createContext<AppState | undefined>(undefined);

export function AppStateProvider({ children }: { children: ReactNode }) {
  const [isRunning, setIsRunning] = useState(false);
  const [tasks, setTasks] = useState<CodingTask[]>([]);
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const [systemMetrics, setSystemMetrics] =
    useState<SystemMetrics>(defaultMetrics);
  const [isLoading, setIsLoading] = useState(true);
  const [startTime, setStartTime] = useState<number | null>(null);
  
  // Use ref to track the latest tasks for async operations
  const tasksRef = useRef<CodingTask[]>([]);
  
  useEffect(() => {
    tasksRef.current = tasks;
  }, [tasks]);

  useEffect(() => {
    loadData();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (isRunning && startTime) {
      interval = setInterval(() => {
        setSystemMetrics((prev) => ({
          ...prev,
          uptime: (Date.now() - startTime) / 1000,
        }));
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [isRunning, startTime]);

  const loadData = async () => {
    try {
      const [tasksData, logsData, stateData] = await Promise.all([
        AsyncStorage.getItem(STORAGE_KEYS.TASKS),
        AsyncStorage.getItem(STORAGE_KEYS.LOGS),
        AsyncStorage.getItem(STORAGE_KEYS.SYSTEM_STATE),
      ]);

      if (tasksData) {
        const parsedTasks = JSON.parse(tasksData);
        setTasks(parsedTasks);
        updateMetricsFromTasks(parsedTasks);
      }

      if (logsData) {
        setLogs(JSON.parse(logsData));
      }

      if (stateData) {
        const state = JSON.parse(stateData);
        if (state.isRunning) {
          setIsRunning(true);
          setStartTime(state.startTime || Date.now());
        }
      }
    } catch (error) {
      console.error("Error loading data:", error);
    } finally {
      setIsLoading(false);
    }
  };

  const updateMetricsFromTasks = (taskList: CodingTask[]) => {
    const completed = taskList.filter((t) => t.status === "completed");
    const pending = taskList.filter((t) => t.status === "pending");
    const inProgress = taskList.filter((t) => t.status === "inProgress");

    let avgTime = 0;
    if (completed.length > 0) {
      const totalTime = completed.reduce((sum, t) => {
        if (t.completedAt && t.createdAt) {
          return sum + (t.completedAt - t.createdAt) / 1000;
        }
        return sum;
      }, 0);
      avgTime = totalTime / completed.length;
    }

    const successRate =
      taskList.length > 0 ? completed.length / taskList.length : 0;

    setSystemMetrics((prev) => ({
      ...prev,
      tasksProcessed: completed.length,
      tasksInQueue: pending.length,
      activeAgents: inProgress.length > 0 ? Math.min(inProgress.length, 3) : 0,
      averageTaskTime: avgTime,
      improvementSuccessRate: successRate,
    }));
  };

  const saveTasks = async (newTasks: CodingTask[]) => {
    try {
      await AsyncStorage.setItem(STORAGE_KEYS.TASKS, JSON.stringify(newTasks));
    } catch (error) {
      console.error("Error saving tasks:", error);
    }
  };

  const saveLogs = async (newLogs: LogEntry[]) => {
    try {
      const logsToSave = newLogs.slice(-100);
      await AsyncStorage.setItem(STORAGE_KEYS.LOGS, JSON.stringify(logsToSave));
    } catch (error) {
      console.error("Error saving logs:", error);
    }
  };

  const saveSystemState = async (running: boolean, start: number | null) => {
    try {
      await AsyncStorage.setItem(
        STORAGE_KEYS.SYSTEM_STATE,
        JSON.stringify({ isRunning: running, startTime: start }),
      );
    } catch (error) {
      console.error("Error saving system state:", error);
    }
  };

  const addLog = useCallback((level: LogEntry["level"], message: string) => {
    const newLog: LogEntry = {
      id: generateId(),
      level,
      message,
      timestamp: Date.now(),
    };

    setLogs((prev) => {
      const newLogs = [...prev, newLog].slice(-100);
      saveLogs(newLogs);
      return newLogs;
    });
  }, []);

  const startSystem = async () => {
    const now = Date.now();
    setIsRunning(true);
    setStartTime(now);
    setSystemMetrics((prev) => ({
      ...prev,
      activeAgents:
        tasks.filter((t) => t.status === "inProgress").length > 0 ? 3 : 1,
      uptime: 0,
    }));
    await saveSystemState(true, now);
    addLog("info", "System started successfully");
    addLog("notice", "AI agents initialized and ready");
  };

  const stopSystem = async () => {
    setIsRunning(false);
    setStartTime(null);
    setSystemMetrics((prev) => ({
      ...prev,
      activeAgents: 0,
      uptime: 0,
    }));
    await saveSystemState(false, null);
    addLog("warning", "System stopped");
  };

  const sanitizeText = (text: string, maxLength: number): string => {
    return text
      .trim()
      .replace(/[<>]/g, "")
      .replace(/[\x00-\x1F\x7F]/g, "")
      .slice(0, maxLength);
  };

  const addTask = async (
    title: string,
    description: string,
    language: ProgrammingLanguage,
    difficulty: DifficultyLevel,
  ) => {
    if (!title.trim() || !description.trim()) {
      throw new Error("Title and description are required");
    }

    const sanitizedTitle = sanitizeText(title, 100);
    const sanitizedDescription = sanitizeText(description, 1000);

    if (sanitizedTitle.length < 3) {
      throw new Error("Title must be at least 3 characters");
    }

    if (sanitizedDescription.length < 10) {
      throw new Error("Description must be at least 10 characters");
    }

    const newTask: CodingTask = {
      id: generateId(),
      title: sanitizedTitle,
      description: sanitizedDescription,
      language,
      difficulty,
      status: "pending",
      createdAt: Date.now(),
    };

    const newTasks = [newTask, ...tasks];
    setTasks(newTasks);
    await saveTasks(newTasks);
    updateMetricsFromTasks(newTasks);
    addLog("info", `Task created: ${sanitizedTitle}`);

    if (isRunning) {
      setTimeout(() => simulateTaskProcessing(newTask.id), 2000);
    }
  };

  const simulateTaskProcessing = async (taskId: string) => {
    await updateTaskStatus(taskId, "inProgress");
    addLog("debug", `Processing task: ${taskId}`);

    try {
      // Use ref to get the latest task data without side effects
      const task = tasksRef.current.find((t) => t.id === taskId);
      
      if (!task) {
        throw new Error("Task not found");
      }

      const taskData = {
        title: task.title,
        description: task.description,
        language: task.language,
        difficulty: task.difficulty,
      };

      // Import the API dynamically to avoid circular dependencies
      const { generateCode } = await import("@/lib/api");

      addLog("info", `Generating code for task: ${taskData.title}`);

      // Call the actual AI code generation API
      const result = await generateCode(taskData);

      // Update the task with generated code using functional update
      setTasks((currentTasks) => {
        const newTasks = currentTasks.map((t) => {
          if (t.id === taskId) {
            return {
              ...t,
              status: "completed" as TaskStatus,
              completedAt: Date.now(),
              generatedCode: result.code,
              codeExplanation: result.explanation,
            };
          }
          return t;
        });

        saveTasks(newTasks);
        updateMetricsFromTasks(newTasks);
        return newTasks;
      });
      
      addLog("notice", `Task completed successfully: ${taskData.title}`);
    } catch (error) {
      console.error("Error processing task:", error);
      await updateTaskStatus(taskId, "failed");
      addLog(
        "error",
        `Task failed: ${error instanceof Error ? error.message : "Unknown error"}`,
      );
    }
  };

  const updateTaskStatus = async (taskId: string, status: TaskStatus) => {
    setTasks((currentTasks) => {
      const newTasks = currentTasks.map((task) => {
        if (task.id === taskId) {
          return {
            ...task,
            status,
            completedAt:
              status === "completed" || status === "failed"
                ? Date.now()
                : undefined,
          };
        }
        return task;
      });

      saveTasks(newTasks);
      updateMetricsFromTasks(newTasks);
      return newTasks;
    });
  };

  const deleteTask = async (taskId: string) => {
    const newTasks = tasks.filter((task) => task.id !== taskId);
    setTasks(newTasks);
    await saveTasks(newTasks);
    updateMetricsFromTasks(newTasks);
    addLog("info", `Task deleted: ${taskId}`);
  };

  const clearLogs = async () => {
    setLogs([]);
    await AsyncStorage.removeItem(STORAGE_KEYS.LOGS);
    addLog("info", "Logs cleared");
  };

  return (
    <AppStateContext.Provider
      value={{
        isRunning,
        tasks,
        logs,
        systemMetrics,
        startSystem,
        stopSystem,
        addTask,
        updateTaskStatus,
        deleteTask,
        addLog,
        clearLogs,
        isLoading,
      }}
    >
      {children}
    </AppStateContext.Provider>
  );
}

export function useAppState() {
  const context = useContext(AppStateContext);
  if (context === undefined) {
    throw new Error("useAppState must be used within an AppStateProvider");
  }
  return context;
}
