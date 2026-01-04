import React, { useState } from "react";
import { View, StyleSheet, TextInput, Pressable, Alert } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useNavigation } from "@react-navigation/native";
import { Feather } from "@expo/vector-icons";

import { ThemedText } from "@/components/ThemedText";
import { ThemedView } from "@/components/ThemedView";
import { Card } from "@/components/Card";
import { KeyboardAwareScrollViewCompat } from "@/components/KeyboardAwareScrollViewCompat";
import { useTheme } from "@/hooks/useTheme";
import { useAppState } from "@/context/AppStateContext";
import { Spacing, BorderRadius } from "@/constants/theme";
import {
  ProgrammingLanguage,
  DifficultyLevel,
  PROGRAMMING_LANGUAGES,
  DIFFICULTY_LEVELS,
} from "@/types";

export default function TaskCreatorScreen() {
  const { theme } = useTheme();
  const insets = useSafeAreaInsets();
  const navigation = useNavigation();
  const { addTask, isRunning } = useAppState();

  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [language, setLanguage] = useState<ProgrammingLanguage>("swift");
  const [difficulty, setDifficulty] = useState<DifficultyLevel>("medium");
  const [isSubmitting, setIsSubmitting] = useState(false);

  const isValid = title.trim().length > 0 && description.trim().length > 0;

  const handleSubmit = async () => {
    if (!isValid || isSubmitting) return;

    if (title.trim().length < 3) {
      Alert.alert("Invalid Title", "Title must be at least 3 characters long.");
      return;
    }

    if (description.trim().length < 10) {
      Alert.alert(
        "Invalid Description",
        "Description must be at least 10 characters long.",
      );
      return;
    }

    setIsSubmitting(true);
    try {
      await addTask(title, description, language, difficulty);
      navigation.goBack();
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <ThemedView style={styles.container}>
      <KeyboardAwareScrollViewCompat
        contentContainerStyle={[
          styles.content,
          { paddingTop: Spacing.xl, paddingBottom: insets.bottom + Spacing.xl },
        ]}
        showsVerticalScrollIndicator={false}
      >
        {!isRunning && (
          <Card
            style={[
              styles.warningCard,
              { backgroundColor: theme.warning + "20" },
            ]}
          >
            <View style={styles.warningContent}>
              <Feather name="alert-triangle" size={20} color={theme.warning} />
              <ThemedText
                style={[styles.warningText, { color: theme.warning }]}
              >
                System is not running. Tasks will be queued until you start the
                system.
              </ThemedText>
            </View>
          </Card>
        )}

        <Card style={styles.formCard}>
          <ThemedText style={styles.sectionTitle}>Basic Information</ThemedText>

          <View style={styles.inputGroup}>
            <ThemedText style={[styles.label, { color: theme.textSecondary }]}>
              Task Title
            </ThemedText>
            <TextInput
              style={[
                styles.textInput,
                {
                  backgroundColor: theme.backgroundTertiary,
                  color: theme.text,
                  borderColor: theme.border,
                },
              ]}
              value={title}
              onChangeText={setTitle}
              placeholder="Enter task title"
              placeholderTextColor={theme.textSecondary}
              maxLength={100}
              autoCapitalize="sentences"
            />
            <ThemedText
              style={[styles.charCount, { color: theme.textSecondary }]}
            >
              {title.length}/100
            </ThemedText>
          </View>

          <View style={styles.inputGroup}>
            <ThemedText style={[styles.label, { color: theme.textSecondary }]}>
              Description
            </ThemedText>
            <TextInput
              style={[
                styles.textInput,
                styles.textArea,
                {
                  backgroundColor: theme.backgroundTertiary,
                  color: theme.text,
                  borderColor: theme.border,
                },
              ]}
              value={description}
              onChangeText={setDescription}
              placeholder="Describe what you want to build..."
              placeholderTextColor={theme.textSecondary}
              multiline
              numberOfLines={4}
              maxLength={1000}
              textAlignVertical="top"
            />
            <ThemedText
              style={[styles.charCount, { color: theme.textSecondary }]}
            >
              {description.length}/1000
            </ThemedText>
          </View>
        </Card>

        <Card style={styles.formCard}>
          <ThemedText style={styles.sectionTitle}>Configuration</ThemedText>

          <View style={styles.inputGroup}>
            <ThemedText style={[styles.label, { color: theme.textSecondary }]}>
              Programming Language
            </ThemedText>
            <View style={styles.optionsGrid}>
              {PROGRAMMING_LANGUAGES.map((lang) => (
                <Pressable
                  key={lang.value}
                  onPress={() => setLanguage(lang.value)}
                  style={({ pressed }) => [
                    styles.optionButton,
                    {
                      backgroundColor:
                        language === lang.value
                          ? theme.primary + "20"
                          : theme.backgroundTertiary,
                      borderColor:
                        language === lang.value ? theme.primary : theme.border,
                      opacity: pressed ? 0.8 : 1,
                    },
                  ]}
                >
                  <ThemedText
                    style={[
                      styles.optionText,
                      {
                        color:
                          language === lang.value ? theme.primary : theme.text,
                      },
                    ]}
                  >
                    {lang.label}
                  </ThemedText>
                </Pressable>
              ))}
            </View>
          </View>

          <View style={styles.inputGroup}>
            <ThemedText style={[styles.label, { color: theme.textSecondary }]}>
              Difficulty Level
            </ThemedText>
            <View style={styles.difficultyRow}>
              {DIFFICULTY_LEVELS.map((level) => (
                <Pressable
                  key={level.value}
                  onPress={() => setDifficulty(level.value)}
                  style={({ pressed }) => [
                    styles.difficultyButton,
                    {
                      backgroundColor:
                        difficulty === level.value
                          ? theme.primary + "20"
                          : theme.backgroundTertiary,
                      borderColor:
                        difficulty === level.value
                          ? theme.primary
                          : theme.border,
                      opacity: pressed ? 0.8 : 1,
                    },
                  ]}
                >
                  <ThemedText
                    style={[
                      styles.difficultyText,
                      {
                        color:
                          difficulty === level.value
                            ? theme.primary
                            : theme.text,
                      },
                    ]}
                  >
                    {level.label}
                  </ThemedText>
                </Pressable>
              ))}
            </View>
          </View>
        </Card>

        <Pressable
          onPress={handleSubmit}
          disabled={!isValid || isSubmitting}
          style={({ pressed }) => [
            styles.submitButton,
            {
              backgroundColor: isValid
                ? theme.primary
                : theme.backgroundTertiary,
              opacity: pressed && isValid ? 0.8 : 1,
              transform: [{ scale: pressed && isValid ? 0.98 : 1 }],
            },
          ]}
        >
          <Feather
            name={isSubmitting ? "loader" : "plus-circle"}
            size={20}
            color={isValid ? "#FFFFFF" : theme.textSecondary}
          />
          <ThemedText
            style={[
              styles.submitText,
              { color: isValid ? "#FFFFFF" : theme.textSecondary },
            ]}
          >
            {isSubmitting ? "Creating..." : "Create Task"}
          </ThemedText>
        </Pressable>
      </KeyboardAwareScrollViewCompat>
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
  warningCard: {
    padding: Spacing.lg,
  },
  warningContent: {
    flexDirection: "row",
    alignItems: "center",
    gap: Spacing.md,
  },
  warningText: {
    flex: 1,
    fontSize: 14,
    fontWeight: "500",
  },
  formCard: {
    padding: Spacing.lg,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: "600",
    marginBottom: Spacing.lg,
  },
  inputGroup: {
    marginBottom: Spacing.lg,
  },
  label: {
    fontSize: 14,
    fontWeight: "500",
    marginBottom: Spacing.sm,
  },
  textInput: {
    borderRadius: BorderRadius.xs,
    borderWidth: 1,
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.md,
    fontSize: 16,
  },
  textArea: {
    minHeight: 100,
    paddingTop: Spacing.md,
  },
  charCount: {
    fontSize: 12,
    textAlign: "right",
    marginTop: Spacing.xs,
  },
  optionsGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: Spacing.sm,
  },
  optionButton: {
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.sm,
    borderRadius: BorderRadius.xs,
    borderWidth: 1,
  },
  optionText: {
    fontSize: 14,
    fontWeight: "500",
  },
  difficultyRow: {
    flexDirection: "row",
    gap: Spacing.sm,
  },
  difficultyButton: {
    flex: 1,
    paddingVertical: Spacing.md,
    borderRadius: BorderRadius.xs,
    borderWidth: 1,
    alignItems: "center",
  },
  difficultyText: {
    fontSize: 14,
    fontWeight: "500",
  },
  submitButton: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: Spacing.sm,
    paddingVertical: Spacing.lg,
    borderRadius: BorderRadius.sm,
    marginTop: Spacing.md,
  },
  submitText: {
    fontSize: 17,
    fontWeight: "600",
  },
});
