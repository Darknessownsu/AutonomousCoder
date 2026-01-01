import React from "react";
import { View, StyleSheet } from "react-native";

import { ThemedText } from "@/components/ThemedText";
import { useTheme } from "@/hooks/useTheme";
import { Spacing } from "@/constants/theme";

export default function HeaderTitle() {
  const { theme } = useTheme();

  return (
    <View style={styles.container}>
      <View style={[styles.iconContainer, { backgroundColor: theme.primary }]}>
        <ThemedText style={styles.iconText}>AC</ThemedText>
      </View>
      <ThemedText style={styles.title}>AutonomousCoder</ThemedText>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "flex-start",
  },
  iconContainer: {
    width: 28,
    height: 28,
    borderRadius: 6,
    alignItems: "center",
    justifyContent: "center",
    marginRight: Spacing.sm,
  },
  iconText: {
    color: "#FFFFFF",
    fontSize: 12,
    fontWeight: "700",
  },
  title: {
    fontSize: 17,
    fontWeight: "600",
  },
});
