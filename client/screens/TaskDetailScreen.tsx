import React, { useState } from "react";
import {
  View,
  StyleSheet,
  ScrollView,
  Pressable,
  Clipboard,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useRoute, type RouteProp } from "@react-navigation/native";
import { Feather } from "@expo/vector-icons";

import { ThemedText } from "@/components/ThemedText";
import { ThemedView } from "@/components/ThemedView";
import { Card } from "@/components/Card";
import { useTheme } from "@/hooks/useTheme";
import { useAppState } from "@/context/AppStateContext";
import { Spacing, BorderRadius } from "@/constants/theme";
import { getStatusColor } from "@/types";
import type { RootStackParamList } from "@/navigation/RootStackNavigator";

type TaskDetailRouteProp = RouteProp<RootStackParamList, "TaskDetail">;

export default function TaskDetailScreen() {
  const { theme } = useTheme();
  const insets = useSafeAreaInsets();
  const route = useRoute<TaskDetailRouteProp>();
  const { tasks } = useAppState();
  const [copied, setCopied] = useState(false);

  const task = tasks.find((t) => t.id === route.params.taskId);

  if (!task) {
    return (
      <ThemedView style={styles.container}>
        <View style={styles.errorContainer}>
          <Feather name="alert-circle" size={64} color={theme.error} />
          <ThemedText style={styles.errorText}>Task not found</ThemedText>
        </View>
      </ThemedView>
    );
  }

  const statusColor = getStatusColor(task.status);

  const handleCopyCode = async () => {
    if (task.generatedCode) {
      Clipboard.setString(task.generatedCode);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  const formatDate = (timestamp: number) => {
    const date = new Date(timestamp);
    return date.toLocaleString(undefined, {
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  return (
    <ThemedView style={styles.container}>
      <ScrollView
        contentContainerStyle={[
          styles.content,
          { paddingTop: Spacing.xl, paddingBottom: insets.bottom + Spacing.xl },
        ]}
        showsVerticalScrollIndicator={false}
      >
        {/* Task Info Card */}
        <Card style={styles.card}>
          <View style={styles.headerRow}>
            <ThemedText style={styles.title}>{task.title}</ThemedText>
            <View
              style={[
                styles.statusBadge,
                { backgroundColor: statusColor + "20" },
              ]}
            >
              <View
                style={[styles.statusDot, { backgroundColor: statusColor }]}
              />
              <ThemedText style={[styles.statusText, { color: statusColor }]}>
                {task.status === "inProgress"
                  ? "In Progress"
                  : task.status.charAt(0).toUpperCase() + task.status.slice(1)}
              </ThemedText>
            </View>
          </View>

          <View style={styles.metaRow}>
            <View
              style={[styles.tag, { backgroundColor: theme.primary + "20" }]}
            >
              <Feather name="code" size={12} color={theme.primary} />
              <ThemedText style={[styles.tagText, { color: theme.primary }]}>
                {task.language.toUpperCase()}
              </ThemedText>
            </View>
            <View
              style={[
                styles.tag,
                { backgroundColor: theme.backgroundTertiary },
              ]}
            >
              <Feather
                name="bar-chart-2"
                size={12}
                color={theme.textSecondary}
              />
              <ThemedText
                style={[styles.tagText, { color: theme.textSecondary }]}
              >
                {task.difficulty.charAt(0).toUpperCase() +
                  task.difficulty.slice(1)}
              </ThemedText>
            </View>
          </View>

          <View style={[styles.section, { borderTopColor: theme.border }]}>
            <ThemedText
              style={[styles.sectionLabel, { color: theme.textSecondary }]}
            >
              Description
            </ThemedText>
            <ThemedText style={styles.description}>
              {task.description}
            </ThemedText>
          </View>

          <View style={styles.dateRow}>
            <ThemedText
              style={[styles.dateLabel, { color: theme.textSecondary }]}
            >
              Created: {formatDate(task.createdAt)}
            </ThemedText>
            {task.completedAt && (
              <ThemedText
                style={[styles.dateLabel, { color: theme.textSecondary }]}
              >
                Completed: {formatDate(task.completedAt)}
              </ThemedText>
            )}
          </View>
        </Card>

        {/* Explanation Card */}
        {task.codeExplanation && (
          <Card style={styles.card}>
            <View style={styles.cardHeader}>
              <Feather name="info" size={20} color={theme.primary} />
              <ThemedText style={styles.cardTitle}>Explanation</ThemedText>
            </View>
            <ThemedText
              style={[styles.explanation, { color: theme.textSecondary }]}
            >
              {task.codeExplanation}
            </ThemedText>
          </Card>
        )}

        {/* Generated Code Card */}
        {task.generatedCode && (
          <Card style={styles.card}>
            <View style={styles.cardHeader}>
              <Feather name="file-text" size={20} color={theme.success} />
              <ThemedText style={styles.cardTitle}>Generated Code</ThemedText>
              <Pressable
                onPress={handleCopyCode}
                style={({ pressed }) => [
                  styles.copyButton,
                  {
                    backgroundColor: theme.backgroundTertiary,
                    opacity: pressed ? 0.6 : 1,
                  },
                ]}
              >
                <Feather
                  name={copied ? "check" : "copy"}
                  size={16}
                  color={copied ? theme.success : theme.text}
                />
                <ThemedText
                  style={[
                    styles.copyButtonText,
                    { color: copied ? theme.success : theme.text },
                  ]}
                >
                  {copied ? "Copied!" : "Copy"}
                </ThemedText>
              </Pressable>
            </View>
            <View
              style={[
                styles.codeContainer,
                { backgroundColor: theme.backgroundTertiary },
              ]}
            >
              <ScrollView horizontal showsHorizontalScrollIndicator={false}>
                <ThemedText style={styles.code}>
                  {task.generatedCode}
                </ThemedText>
              </ScrollView>
            </View>
          </Card>
        )}

        {/* No Code Generated State */}
        {!task.generatedCode && task.status !== "inProgress" && (
          <Card style={styles.card}>
            <View style={styles.noCodeContainer}>
              <Feather
                name={task.status === "failed" ? "x-circle" : "clock"}
                size={48}
                color={
                  task.status === "failed" ? theme.error : theme.textSecondary
                }
              />
              <ThemedText style={styles.noCodeTitle}>
                {task.status === "failed"
                  ? "Code Generation Failed"
                  : "No Code Generated"}
              </ThemedText>
              <ThemedText
                style={[styles.noCodeMessage, { color: theme.textSecondary }]}
              >
                {task.status === "failed"
                  ? "There was an error generating code for this task."
                  : task.status === "pending"
                    ? "This task is waiting to be processed."
                    : task.status === "cancelled"
                      ? "This task was cancelled."
                      : "Code generation has not started yet."}
              </ThemedText>
            </View>
          </Card>
        )}
      </ScrollView>
    </ThemedView>
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
  errorContainer: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    gap: Spacing.lg,
  },
  errorText: {
    fontSize: 18,
    fontWeight: "600",
  },
  card: {
    padding: Spacing.lg,
  },
  headerRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "flex-start",
    gap: Spacing.md,
    marginBottom: Spacing.md,
  },
  title: {
    fontSize: 22,
    fontWeight: "700",
    flex: 1,
  },
  statusBadge: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    paddingHorizontal: Spacing.sm,
    paddingVertical: 4,
    borderRadius: BorderRadius.full,
  },
  statusDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
  },
  statusText: {
    fontSize: 12,
    fontWeight: "500",
  },
  metaRow: {
    flexDirection: "row",
    gap: Spacing.sm,
    marginBottom: Spacing.lg,
  },
  tag: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
    paddingHorizontal: Spacing.sm,
    paddingVertical: 4,
    borderRadius: 4,
  },
  tagText: {
    fontSize: 11,
    fontWeight: "600",
  },
  section: {
    paddingTop: Spacing.md,
    borderTopWidth: StyleSheet.hairlineWidth,
    gap: Spacing.sm,
  },
  sectionLabel: {
    fontSize: 13,
    fontWeight: "600",
    textTransform: "uppercase",
    letterSpacing: 0.5,
  },
  description: {
    fontSize: 16,
    lineHeight: 24,
  },
  dateRow: {
    marginTop: Spacing.md,
    gap: Spacing.xs,
  },
  dateLabel: {
    fontSize: 12,
  },
  cardHeader: {
    flexDirection: "row",
    alignItems: "center",
    gap: Spacing.sm,
    marginBottom: Spacing.md,
  },
  cardTitle: {
    fontSize: 18,
    fontWeight: "600",
    flex: 1,
  },
  copyButton: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
    paddingHorizontal: Spacing.sm,
    paddingVertical: 4,
    borderRadius: BorderRadius.xs,
  },
  copyButtonText: {
    fontSize: 12,
    fontWeight: "500",
  },
  explanation: {
    fontSize: 15,
    lineHeight: 22,
  },
  codeContainer: {
    padding: Spacing.md,
    borderRadius: BorderRadius.xs,
  },
  code: {
    fontFamily: "monospace",
    fontSize: 13,
    lineHeight: 20,
  },
  noCodeContainer: {
    alignItems: "center",
    gap: Spacing.md,
    paddingVertical: Spacing.xl,
  },
  noCodeTitle: {
    fontSize: 18,
    fontWeight: "600",
  },
  noCodeMessage: {
    fontSize: 15,
    textAlign: "center",
  },
});
