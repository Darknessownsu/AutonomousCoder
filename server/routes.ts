import type { Express } from "express";
import { createServer, type Server } from "node:http";
import { aiService } from "./lib/ai-service";
import { generateCodeRequestSchema } from "../shared/schema";
import { fromError } from "zod-validation-error";

export async function registerRoutes(app: Express): Promise<Server> {
  // put application routes here
  // prefix all routes with /api

  // AI Code Generation endpoint
  app.post("/api/generate-code", async (req, res) => {
    try {
      const validation = generateCodeRequestSchema.safeParse(req.body);
      
      if (!validation.success) {
        const validationError = fromError(validation.error);
        return res.status(400).json({ 
          error: "Invalid request",
          message: validationError.toString()
        });
      }

      const result = await aiService.generateCode(validation.data);
      
      res.json(result);
    } catch (error) {
      console.error("Error generating code:", error);
      res.status(500).json({ 
        error: "Failed to generate code",
        message: error instanceof Error ? error.message : "Unknown error"
      });
    }
  });

  // Health check endpoint
  app.get("/api/health", (req, res) => {
    res.json({ status: "ok", timestamp: new Date().toISOString() });
  });

  const httpServer = createServer(app);

  return httpServer;
}
