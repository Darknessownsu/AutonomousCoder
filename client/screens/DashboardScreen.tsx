import React from "react";
import { View, StyleSheet, ScrollView, Pressable } from "react-native";
import { useBottomTabBarHeight } from "@react-navigation/bottom-tabs";
import { useHeaderHeight } from "@react-navigation/elements";
import { Feather } from "@expo/vector-icons";
import { useNavigation } from "@react-navigation/native";
import type { NativeStackNavigationProp } from "@react-navigation/native-stack";

import { ThemedText } from "@/components/ThemedText";
import { Card } from "@/components/Card";
import { useTheme } from "@/hooks/useTheme";
import { useAppState } from "@/context/AppStateContext";
import { Spacing, BorderRadius } from "@/constants/theme";
import { formatTimeInterval } from "@/types";
import type { RootStackParamList } from "@/navigation/RootStackNavigator";

type NavigationProp = NativeStackNavigationProp<RootStackParamList>;

export default function DashboardScreen() {
  const { theme } = useTheme();
  const tabBarHeight = useBottomTabBarHeight();
  const headerHeight = useHeaderHeight();
  const { isRunning, systemMetrics, startSystem, stopSystem, tasks } =
    useAppState();
  const navigation = useNavigation<NavigationProp>();

  const recentTasks = tasks.slice(0, 3);

  const handleSystemToggle = async () => {
    if (isRunning) {
      await stopSystem();
    } else {
      await startSystem();
    }
  };

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={[
        styles.content,
        {
          paddingTop: headerHeight + Spacing.xl,
          paddingBottom: tabBarHeight + Spacing.xl,
        },
      ]}
      showsVerticalScrollIndicator={false}
    >
      <Card style={styles.statusCard}>
        <View style={styles.statusHeader}>
          <View>
            <ThemedText style={styles.sectionTitle}>System Status</ThemedText>
            <View style={styles.statusRow}>
              <View
                style={[
                  styles.statusIndicator,
                  { backgroundColor: isRunning ? theme.success : theme.error },
                ]}
              />
              <ThemedText
                style={[
                  styles.statusText,
                  { color: isRunning ? theme.success : theme.error },
                ]}
              >
                {isRunning ? "Running" : "Stopped"}
              </ThemedText>
            </View>
            {isRunning && (
              <ThemedText
                style={[styles.uptimeText, { color: theme.textSecondary }]}
              >
                Uptime: {formatTimeInterval(systemMetrics.uptime)}
              </ThemedText>
            )}
          </View>
          <Pressable
            onPress={handleSystemToggle}
            style={({ pressed }) => [
              styles.controlButton,
              {
                backgroundColor: isRunning ? theme.error : theme.primary,
                opacity: pressed ? 0.8 : 1,
                transform: [{ scale: pressed ? 0.96 : 1 }],
              },
            ]}
          >
            <Feather
              name={isRunning ? "square" : "play"}
              size={16}
              color="#FFFFFF"
            />
            <ThemedText style={styles.controlButtonText}>
              {isRunning ? "Stop" : "Start"}
            </ThemedText>
          </Pressable>
        </View>
      </Card>

      <View style={styles.metricsGrid}>
        <MetricCard
          title="Tasks Processed"
          value={systemMetrics.tasksProcessed.toString()}
          icon="check-circle"
          color={theme.success}
          theme={theme}
        />
        <MetricCard
          title="In Queue"
          value={systemMetrics.tasksInQueue.toString()}
          icon="clock"
          color={theme.warning}
          theme={theme}
        />
        <MetricCard
          title="Active Agents"
          value={systemMetrics.activeAgents.toString()}
          icon="cpu"
          color={theme.primary}
          theme={theme}
        />
        <MetricCard
          title="Success Rate"
          value={`${(systemMetrics.improvementSuccessRate * 100).toFixed(0)}%`}
          icon="trending-up"
          color="#AF52DE"
          theme={theme}
        />
      </View>

      <Card style={styles.quickActionsCard}>
        <ThemedText style={styles.sectionTitle}>Quick Actions</ThemedText>
        <Pressable
          onPress={() => navigation.navigate("TaskCreator")}
          style={({ pressed }) => [
            styles.actionButton,
            {
              backgroundColor: theme.primary,
              opacity: pressed ? 0.8 : 1,
              transform: [{ scale: pressed ? 0.96 : 1 }],
            },
          ]}
        >
          <Feather name="plus-circle" size={20} color="#FFFFFF" />
          <ThemedText style={styles.actionButtonText}>
            Create New Task
          </ThemedText>
        </Pressable>
      </Card>

      <Card style={styles.recentTasksCard}>
        <ThemedText style={styles.sectionTitle}>Recent Tasks</ThemedText>
        {recentTasks.length === 0 ? (
          <ThemedText
            style={[styles.emptyText, { color: theme.textSecondary }]}
          >
            No tasks yet. Create your first task to get started.
          </ThemedText>
        ) : (
          recentTasks.map((task) => (
            <TaskRow key={task.id} task={task} theme={theme} />
          ))
        )}
      </Card>
    </ScrollView>
  );
}

function MetricCard({
  title,
  value,
  icon,
  color,
  theme,
}: {
  title: string;
  value: string;
  icon: keyof typeof Feather.glyphMap;
  color: string;
  theme: any;
}) {
  return (
    <Card style={styles.metricCard}>
      <Feather name={icon} size={24} color={color} />
      <ThemedText style={styles.metricValue}>{value}</ThemedText>
      <ThemedText style={[styles.metricTitle, { color: theme.textSecondary }]}>
        {title}
      </ThemedText>
    </Card>
  );
}

function TaskRow({ task, theme }: { task: any; theme: any }) {
  const statusColors: Record<string, string> = {
    pending: theme.warning,
    inProgress: theme.primary,
    completed: theme.success,
    failed: theme.error,
    cancelled: theme.textSecondary,
  };

  return (
    <View style={[styles.taskRow, { borderBottomColor: theme.border }]}>
      <View style={styles.taskInfo}>
        <ThemedText style={styles.taskTitle} numberOfLines={1}>
          {task.title}
        </ThemedText>
        <View style={styles.taskMeta}>
          <View
            style={[
              styles.languageTag,
              { backgroundColor: theme.primary + "33" },
            ]}
          >
            <ThemedText style={[styles.languageText, { color: theme.primary }]}>
              {task.language.toUpperCase()}
            </ThemedText>
          </View>
          <ThemedText
            style={[
              styles.statusLabel,
              { color: statusColors[task.status] || theme.textSecondary },
            ]}
          >
            {task.status.charAt(0).toUpperCase() + task.status.slice(1)}
          </ThemedText>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  content: {
    paddingHorizontal: Spacing.lg,
    gap: Spacing.lg,
  },
  statusCard: {
    padding: Spacing.lg,
  },
  statusHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "flex-start",
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: "600",
    marginBottom: Spacing.sm,
  },
  statusRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: Spacing.sm,
  },
  statusIndicator: {
    width: 12,
    height: 12,
    borderRadius: 6,
  },
  statusText: {
    fontSize: 17,
    fontWeight: "600",
  },
  uptimeText: {
    fontSize: 13,
    marginTop: Spacing.xs,
  },
  controlButton: {
    flexDirection: "row",
    alignItems: "center",
    gap: Spacing.sm,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.md,
    borderRadius: BorderRadius.xs,
  },
  controlButtonText: {
    color: "#FFFFFF",
    fontSize: 15,
    fontWeight: "600",
  },
  metricsGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: Spacing.md,
  },
  metricCard: {
    width: "47%",
    padding: Spacing.lg,
    alignItems: "center",
    gap: Spacing.sm,
  },
  metricValue: {
    fontSize: 28,
    fontWeight: "700",
  },
  metricTitle: {
    fontSize: 12,
    textAlign: "center",
  },
  quickActionsCard: {
    padding: Spacing.lg,
  },
  actionButton: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: Spacing.sm,
    paddingVertical: Spacing.md,
    borderRadius: BorderRadius.xs,
  },
  actionButtonText: {
    color: "#FFFFFF",
    fontSize: 16,
    fontWeight: "600",
  },
  recentTasksCard: {
    padding: Spacing.lg,
  },
  emptyText: {
    fontSize: 15,
    textAlign: "center",
    paddingVertical: Spacing.xl,
  },
  taskRow: {
    paddingVertical: Spacing.md,
    borderBottomWidth: StyleSheet.hairlineWidth,
  },
  taskInfo: {
    gap: Spacing.xs,
  },
  taskTitle: {
    fontSize: 16,
    fontWeight: "600",
  },
  taskMeta: {
    flexDirection: "row",
    alignItems: "center",
    gap: Spacing.sm,
  },
  languageTag: {
    paddingHorizontal: Spacing.sm,
    paddingVertical: 2,
    borderRadius: 4,
  },
  languageText: {
    fontSize: 11,
    fontWeight: "600",
  },
  statusLabel: {
    fontSize: 13,
  },
});
