import Constants from "expo-constants";

const API_URL =
  Constants.expoConfig?.extra?.apiUrl ||
  (typeof window !== "undefined" && window.location
    ? `${window.location.protocol}//${window.location.hostname}:5000`
    : "http://localhost:5000");

interface GenerateCodeRequest {
  title: string;
  description: string;
  language: string;
  difficulty: string;
}

interface GenerateCodeResponse {
  code: string;
  explanation: string;
  language: string;
}

export async function generateCode(
  params: GenerateCodeRequest,
): Promise<GenerateCodeResponse> {
  const response = await fetch(`${API_URL}/api/generate-code`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(params),
  });

  if (!response.ok) {
    const error = await response
      .json()
      .catch(() => ({ message: "Failed to generate code" }));
    throw new Error(error.message || "Failed to generate code");
  }

  return response.json();
}

export async function healthCheck(): Promise<{
  status: string;
  timestamp: string;
}> {
  const response = await fetch(`${API_URL}/api/health`);
  return response.json();
}
