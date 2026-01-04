import React from "react";
import { View, StyleSheet, FlatList, Pressable } from "react-native";
import { useBottomTabBarHeight } from "@react-navigation/bottom-tabs";
import { useHeaderHeight } from "@react-navigation/elements";
import { Feather } from "@expo/vector-icons";

import { ThemedText } from "@/components/ThemedText";
import { ThemedView } from "@/components/ThemedView";
import { useTheme } from "@/hooks/useTheme";
import { useAppState } from "@/context/AppStateContext";
import { Spacing, Fonts } from "@/constants/theme";
import { LogEntry, getLogLevelColor } from "@/types";

export default function LogsScreen() {
  const { theme } = useTheme();
  const tabBarHeight = useBottomTabBarHeight();
  const headerHeight = useHeaderHeight();
  const { logs, clearLogs } = useAppState();

  const sortedLogs = [...logs].reverse();

  const formatTime = (timestamp: number) => {
    const date = new Date(timestamp);
    return date.toLocaleTimeString(undefined, {
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
    });
  };

  const renderLogEntry = ({ item }: { item: LogEntry }) => {
    const levelColor = getLogLevelColor(item.level);

    return (
      <View style={[styles.logEntry, { borderBottomColor: theme.border }]}>
        <View style={styles.logHeader}>
          <View
            style={[styles.levelIndicator, { backgroundColor: levelColor }]}
          />
          <ThemedText style={[styles.logLevel, { color: levelColor }]}>
            {item.level.toUpperCase()}
          </ThemedText>
          <ThemedText
            style={[styles.timestamp, { color: theme.textSecondary }]}
          >
            {formatTime(item.timestamp)}
          </ThemedText>
        </View>
        <ThemedText style={[styles.logMessage, { fontFamily: Fonts?.mono }]}>
          {item.message}
        </ThemedText>
      </View>
    );
  };

  const renderEmptyState = () => (
    <View style={styles.emptyContainer}>
      <Feather name="file-text" size={64} color={theme.textSecondary} />
      <ThemedText style={styles.emptyTitle}>No Logs</ThemedText>
      <ThemedText style={[styles.emptyMessage, { color: theme.textSecondary }]}>
        System logs will appear here when the system is running.
      </ThemedText>
    </View>
  );

  return (
    <ThemedView style={styles.container}>
      {logs.length > 0 && (
        <View
          style={[styles.header, { paddingTop: headerHeight + Spacing.md }]}
        >
          <ThemedText style={[styles.logCount, { color: theme.textSecondary }]}>
            {logs.length} log entries
          </ThemedText>
          <Pressable
            onPress={clearLogs}
            style={({ pressed }) => [
              styles.clearButton,
              { opacity: pressed ? 0.6 : 1 },
            ]}
          >
            <Feather name="trash-2" size={16} color={theme.error} />
            <ThemedText style={[styles.clearText, { color: theme.error }]}>
              Clear
            </ThemedText>
          </Pressable>
        </View>
      )}
      <FlatList
        data={sortedLogs}
        keyExtractor={(item) => item.id}
        renderItem={renderLogEntry}
        contentContainerStyle={[
          styles.listContent,
          {
            paddingTop:
              logs.length > 0 ? Spacing.md : headerHeight + Spacing.xl,
            paddingBottom: tabBarHeight + Spacing.xl,
          },
          logs.length === 0 && styles.emptyList,
        ]}
        ListEmptyComponent={renderEmptyState}
        showsVerticalScrollIndicator={false}
      />
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingHorizontal: Spacing.lg,
    paddingBottom: Spacing.sm,
  },
  logCount: {
    fontSize: 14,
  },
  clearButton: {
    flexDirection: "row",
    alignItems: "center",
    gap: Spacing.xs,
  },
  clearText: {
    fontSize: 14,
    fontWeight: "500",
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
  logEntry: {
    paddingVertical: Spacing.md,
    borderBottomWidth: StyleSheet.hairlineWidth,
  },
  logHeader: {
    flexDirection: "row",
    alignItems: "center",
    gap: Spacing.sm,
    marginBottom: Spacing.xs,
  },
  levelIndicator: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  logLevel: {
    fontSize: 11,
    fontWeight: "700",
    letterSpacing: 0.5,
  },
  timestamp: {
    fontSize: 12,
    marginLeft: "auto",
  },
  logMessage: {
    fontSize: 14,
    lineHeight: 20,
  },
});
