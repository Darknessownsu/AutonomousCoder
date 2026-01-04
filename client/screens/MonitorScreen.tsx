import React from "react";
import { View, StyleSheet, ScrollView } from "react-native";
import { useBottomTabBarHeight } from "@react-navigation/bottom-tabs";
import { useHeaderHeight } from "@react-navigation/elements";
import { Feather } from "@expo/vector-icons";

import { ThemedText } from "@/components/ThemedText";
import { ThemedView } from "@/components/ThemedView";
import { Card } from "@/components/Card";
import { useTheme } from "@/hooks/useTheme";
import { useAppState } from "@/context/AppStateContext";
import { Spacing, BorderRadius } from "@/constants/theme";
import { formatTimeInterval } from "@/types";

export default function MonitorScreen() {
  const { theme } = useTheme();
  const tabBarHeight = useBottomTabBarHeight();
  const headerHeight = useHeaderHeight();
  const { isRunning, systemMetrics } = useAppState();

  if (!isRunning) {
    return (
      <ThemedView style={styles.container}>
        <View
          style={[
            styles.emptyContainer,
            {
              paddingTop: headerHeight + Spacing.xl,
              paddingBottom: tabBarHeight + Spacing.xl,
            },
          ]}
        >
          <Feather name="activity" size={64} color={theme.textSecondary} />
          <ThemedText style={styles.emptyTitle}>System Not Running</ThemedText>
          <ThemedText
            style={[styles.emptyMessage, { color: theme.textSecondary }]}
          >
            Start the system from the Dashboard to view monitoring data.
          </ThemedText>
        </View>
      </ThemedView>
    );
  }

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
      <Card style={styles.sectionCard}>
        <ThemedText style={styles.sectionTitle}>Performance Metrics</ThemedText>
        <View style={styles.metricsGrid}>
          <MetricRow
            label="Average Task Time"
            value={formatTimeInterval(systemMetrics.averageTaskTime)}
            theme={theme}
          />
          <MetricRow
            label="Tasks Processed"
            value={systemMetrics.tasksProcessed.toString()}
            theme={theme}
          />
          <MetricRow
            label="Tasks in Queue"
            value={systemMetrics.tasksInQueue.toString()}
            theme={theme}
          />
        </View>
      </Card>

      <Card style={styles.sectionCard}>
        <ThemedText style={styles.sectionTitle}>System Metrics</ThemedText>
        <View style={styles.metricsGrid}>
          <MetricRow
            label="Uptime"
            value={formatTimeInterval(systemMetrics.uptime)}
            theme={theme}
          />
          <MetricRow
            label="Active Agents"
            value={systemMetrics.activeAgents.toString()}
            theme={theme}
          />
        </View>
      </Card>

      <Card style={styles.sectionCard}>
        <ThemedText style={styles.sectionTitle}>Self-Improvement</ThemedText>
        <View style={styles.progressContainer}>
          <View style={styles.progressHeader}>
            <ThemedText
              style={[styles.progressLabel, { color: theme.textSecondary }]}
            >
              Success Rate
            </ThemedText>
            <ThemedText style={styles.progressValue}>
              {(systemMetrics.improvementSuccessRate * 100).toFixed(1)}%
            </ThemedText>
          </View>
          <View
            style={[
              styles.progressBar,
              { backgroundColor: theme.backgroundTertiary },
            ]}
          >
            <View
              style={[
                styles.progressFill,
                {
                  backgroundColor: theme.success,
                  width: `${systemMetrics.improvementSuccessRate * 100}%`,
                },
              ]}
            />
          </View>
        </View>
      </Card>

      <Card style={styles.sectionCard}>
        <ThemedText style={styles.sectionTitle}>Agent Status</ThemedText>
        <View style={styles.agentsGrid}>
          <AgentCard
            name="Code Generation"
            status={systemMetrics.activeAgents > 0 ? "active" : "idle"}
            icon="code"
            theme={theme}
          />
          <AgentCard
            name="Debugging"
            status={systemMetrics.activeAgents > 1 ? "active" : "idle"}
            icon="tool"
            theme={theme}
          />
          <AgentCard
            name="Optimization"
            status={systemMetrics.activeAgents > 2 ? "active" : "idle"}
            icon="zap"
            theme={theme}
          />
        </View>
      </Card>
    </ScrollView>
  );
}

function MetricRow({
  label,
  value,
  theme,
}: {
  label: string;
  value: string;
  theme: any;
}) {
  return (
    <View style={[styles.metricRow, { borderBottomColor: theme.border }]}>
      <ThemedText style={[styles.metricLabel, { color: theme.textSecondary }]}>
        {label}
      </ThemedText>
      <ThemedText style={styles.metricValue}>{value}</ThemedText>
    </View>
  );
}

function AgentCard({
  name,
  status,
  icon,
  theme,
}: {
  name: string;
  status: "active" | "idle";
  icon: keyof typeof Feather.glyphMap;
  theme: any;
}) {
  const isActive = status === "active";

  return (
    <View
      style={[
        styles.agentCard,
        {
          backgroundColor: isActive
            ? theme.primary + "15"
            : theme.backgroundTertiary,
          borderColor: isActive ? theme.primary + "40" : "transparent",
        },
      ]}
    >
      <Feather
        name={icon}
        size={24}
        color={isActive ? theme.primary : theme.textSecondary}
      />
      <ThemedText style={styles.agentName}>{name}</ThemedText>
      <View style={styles.agentStatusRow}>
        <View
          style={[
            styles.agentStatusDot,
            { backgroundColor: isActive ? theme.success : theme.textSecondary },
          ]}
        />
        <ThemedText
          style={[
            styles.agentStatus,
            { color: isActive ? theme.success : theme.textSecondary },
          ]}
        >
          {isActive ? "Active" : "Idle"}
        </ThemedText>
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
  emptyContainer: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    paddingHorizontal: Spacing["3xl"],
    gap: Spacing.lg,
  },
  emptyTitle: {
    fontSize: 22,
    fontWeight: "600",
    marginTop: Spacing.md,
  },
  emptyMessage: {
    fontSize: 16,
    textAlign: "center",
  },
  sectionCard: {
    padding: Spacing.lg,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: "600",
    marginBottom: Spacing.lg,
  },
  metricsGrid: {
    gap: Spacing.xs,
  },
  metricRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingVertical: Spacing.md,
    borderBottomWidth: StyleSheet.hairlineWidth,
  },
  metricLabel: {
    fontSize: 15,
  },
  metricValue: {
    fontSize: 17,
    fontWeight: "600",
  },
  progressContainer: {
    gap: Spacing.sm,
  },
  progressHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  },
  progressLabel: {
    fontSize: 15,
  },
  progressValue: {
    fontSize: 17,
    fontWeight: "600",
  },
  progressBar: {
    height: 8,
    borderRadius: 4,
    overflow: "hidden",
  },
  progressFill: {
    height: "100%",
    borderRadius: 4,
  },
  agentsGrid: {
    gap: Spacing.md,
  },
  agentCard: {
    flexDirection: "row",
    alignItems: "center",
    gap: Spacing.md,
    padding: Spacing.lg,
    borderRadius: BorderRadius.sm,
    borderWidth: 1,
  },
  agentName: {
    flex: 1,
    fontSize: 16,
    fontWeight: "500",
  },
  agentStatusRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
  },
  agentStatusDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  agentStatus: {
    fontSize: 13,
    fontWeight: "500",
  },
});
