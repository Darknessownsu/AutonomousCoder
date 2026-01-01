import React from "react";
import { View, StyleSheet, FlatList, Pressable, Alert } from "react-native";
import { useBottomTabBarHeight } from "@react-navigation/bottom-tabs";
import { useHeaderHeight } from "@react-navigation/elements";
import { useNavigation } from "@react-navigation/native";
import type { NativeStackNavigationProp } from "@react-navigation/native-stack";
import { Feather } from "@expo/vector-icons";

import { ThemedText } from "@/components/ThemedText";
import { ThemedView } from "@/components/ThemedView";
import { Card } from "@/components/Card";
import { useTheme } from "@/hooks/useTheme";
import { useAppState } from "@/context/AppStateContext";
import { Spacing, BorderRadius } from "@/constants/theme";
import { CodingTask, getStatusColor } from "@/types";
import type { RootStackParamList } from "@/navigation/RootStackNavigator";

type NavigationProp = NativeStackNavigationProp<RootStackParamList>;

export default function TasksScreen() {
  const { theme } = useTheme();
  const tabBarHeight = useBottomTabBarHeight();
  const headerHeight = useHeaderHeight();
  const navigation = useNavigation<NavigationProp>();
  const { tasks, deleteTask, updateTaskStatus } = useAppState();

  const handleDeleteTask = (task: CodingTask) => {
    Alert.alert(
      "Delete Task",
      `Are you sure you want to delete "${task.title}"?`,
      [
        { text: "Cancel", style: "cancel" },
        {
          text: "Delete",
          style: "destructive",
          onPress: () => deleteTask(task.id),
        },
      ],
    );
  };

  const handleCancelTask = (task: CodingTask) => {
    if (task.status === "pending" || task.status === "inProgress") {
      updateTaskStatus(task.id, "cancelled");
    }
  };

  const renderTask = ({ item }: { item: CodingTask }) => (
    <TaskCard
      task={item}
      theme={theme}
      onDelete={() => handleDeleteTask(item)}
      onCancel={() => handleCancelTask(item)}
    />
  );

  const renderEmptyState = () => (
    <View style={styles.emptyContainer}>
      <Feather name="file-plus" size={64} color={theme.textSecondary} />
      <ThemedText style={styles.emptyTitle}>No Tasks Yet</ThemedText>
      <ThemedText style={[styles.emptyMessage, { color: theme.textSecondary }]}>
        Create your first coding task to get started with autonomous code
        generation.
      </ThemedText>
      <Pressable
        onPress={() => navigation.navigate("TaskCreator")}
        style={({ pressed }) => [
          styles.createButton,
          {
            backgroundColor: theme.primary,
            opacity: pressed ? 0.8 : 1,
            transform: [{ scale: pressed ? 0.96 : 1 }],
          },
        ]}
      >
        <Feather name="plus" size={20} color="#FFFFFF" />
        <ThemedText style={styles.createButtonText}>Create Task</ThemedText>
      </Pressable>
    </View>
  );

  return (
    <ThemedView style={styles.container}>
      <FlatList
        data={tasks}
        keyExtractor={(item) => item.id}
        renderItem={renderTask}
        contentContainerStyle={[
          styles.listContent,
          {
            paddingTop: headerHeight + Spacing.lg,
            paddingBottom: tabBarHeight + Spacing.xl,
          },
          tasks.length === 0 && styles.emptyList,
        ]}
        ListEmptyComponent={renderEmptyState}
        showsVerticalScrollIndicator={false}
        ItemSeparatorComponent={() => <View style={{ height: Spacing.md }} />}
      />
    </ThemedView>
  );
}

function TaskCard({
  task,
  theme,
  onDelete,
  onCancel,
}: {
  task: CodingTask;
  theme: any;
  onDelete: () => void;
  onCancel: () => void;
}) {
  const navigation = useNavigation<NavigationProp>();
  const statusColor = getStatusColor(task.status);
  const canCancel = task.status === "pending" || task.status === "inProgress";
  const hasGeneratedCode = task.status === "completed" && task.generatedCode;

  const formatDate = (timestamp: number) => {
    const date = new Date(timestamp);
    return date.toLocaleDateString(undefined, {
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  const handleViewCode = () => {
    navigation.navigate("TaskDetail", { taskId: task.id });
  };

  return (
    <Card style={styles.taskCard}>
      <View style={styles.taskHeader}>
        <View style={styles.taskTitleRow}>
          <ThemedText style={styles.taskTitle} numberOfLines={1}>
            {task.title}
          </ThemedText>
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
        <ThemedText
          style={[styles.taskDescription, { color: theme.textSecondary }]}
          numberOfLines={2}
        >
          {task.description}
        </ThemedText>
      </View>

      <View style={styles.taskMeta}>
        <View style={styles.metaTags}>
          <View style={[styles.tag, { backgroundColor: theme.primary + "20" }]}>
            <ThemedText style={[styles.tagText, { color: theme.primary }]}>
              {task.language.toUpperCase()}
            </ThemedText>
          </View>
          <View
            style={[styles.tag, { backgroundColor: theme.backgroundTertiary }]}
          >
            <ThemedText
              style={[styles.tagText, { color: theme.textSecondary }]}
            >
              {task.difficulty.charAt(0).toUpperCase() +
                task.difficulty.slice(1)}
            </ThemedText>
          </View>
        </View>
        <ThemedText style={[styles.dateText, { color: theme.textSecondary }]}>
          {formatDate(task.createdAt)}
        </ThemedText>
      </View>

      <View style={[styles.taskActions, { borderTopColor: theme.border }]}>
        {hasGeneratedCode && (
          <Pressable
            onPress={handleViewCode}
            style={({ pressed }) => [
              styles.actionButton,
              { opacity: pressed ? 0.6 : 1 },
            ]}
          >
            <Feather name="code" size={18} color={theme.success} />
            <ThemedText style={[styles.actionText, { color: theme.success }]}>
              View Code
            </ThemedText>
          </Pressable>
        )}
        {canCancel && (
          <Pressable
            onPress={onCancel}
            style={({ pressed }) => [
              styles.actionButton,
              { opacity: pressed ? 0.6 : 1 },
            ]}
          >
            <Feather name="x-circle" size={18} color={theme.warning} />
            <ThemedText style={[styles.actionText, { color: theme.warning }]}>
              Cancel
            </ThemedText>
          </Pressable>
        )}
        <Pressable
          onPress={onDelete}
          style={({ pressed }) => [
            styles.actionButton,
            { opacity: pressed ? 0.6 : 1 },
          ]}
        >
          <Feather name="trash-2" size={18} color={theme.error} />
          <ThemedText style={[styles.actionText, { color: theme.error }]}>
            Delete
          </ThemedText>
        </Pressable>
      </View>
    </Card>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  listContent: {
    paddingHorizontal: Spacing.lg,
  },
  emptyList: {
    flex: 1,
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
  createButton: {
    flexDirection: "row",
    alignItems: "center",
    gap: Spacing.sm,
    paddingHorizontal: Spacing.xl,
    paddingVertical: Spacing.md,
    borderRadius: BorderRadius.xs,
    marginTop: Spacing.md,
  },
  createButtonText: {
    color: "#FFFFFF",
    fontSize: 16,
    fontWeight: "600",
  },
  taskCard: {
    padding: Spacing.lg,
  },
  taskHeader: {
    gap: Spacing.sm,
  },
  taskTitleRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    gap: Spacing.sm,
  },
  taskTitle: {
    fontSize: 17,
    fontWeight: "600",
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
  taskDescription: {
    fontSize: 15,
  },
  taskMeta: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginTop: Spacing.md,
  },
  metaTags: {
    flexDirection: "row",
    gap: Spacing.sm,
  },
  tag: {
    paddingHorizontal: Spacing.sm,
    paddingVertical: 3,
    borderRadius: 4,
  },
  tagText: {
    fontSize: 11,
    fontWeight: "600",
  },
  dateText: {
    fontSize: 12,
  },
  taskActions: {
    flexDirection: "row",
    justifyContent: "flex-end",
    gap: Spacing.xl,
    marginTop: Spacing.md,
    paddingTop: Spacing.md,
    borderTopWidth: StyleSheet.hairlineWidth,
  },
  actionButton: {
    flexDirection: "row",
    alignItems: "center",
    gap: Spacing.xs,
  },
  actionText: {
    fontSize: 14,
    fontWeight: "500",
  },
});
