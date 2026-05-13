// Mock firebase-admin before any imports that trigger initialization.
jest.mock("firebase-admin", () => ({
  apps: [true], // Pretend already initialized so initializeApp() is skipped.
  initializeApp: jest.fn(),
}));

// Mock the firebase-functions v2 https module so no real HTTP server is needed.
jest.mock("firebase-functions/v2/https", () => ({
  onRequest: (handler: (req: unknown, res: unknown) => void) => handler,
}));

import { healthCheck } from "../healthCheck";

type MockResponse = {
  statusCode: number;
  body: unknown;
  status: (code: number) => MockResponse;
  json: (data: unknown) => void;
};

function makeMockResponse(): MockResponse {
  const res = {
    statusCode: 0,
    body: null as unknown,
    status(code: number): MockResponse {
      res.statusCode = code;
      return res;
    },
    json(data: unknown): void {
      res.body = data;
    },
  };
  return res;
}

describe("healthCheck", () => {
  const originalProject = process.env.GCLOUD_PROJECT;

  afterEach(() => {
    if (originalProject === undefined) {
      delete process.env.GCLOUD_PROJECT;
    } else {
      process.env.GCLOUD_PROJECT = originalProject;
    }
  });

  it("returns HTTP 200", () => {
    const res = makeMockResponse();
    (healthCheck as unknown as (req: unknown, res: unknown) => void)({}, res);
    expect(res.statusCode).toBe(200);
  });

  it("returns status: ok", () => {
    const res = makeMockResponse();
    (healthCheck as unknown as (req: unknown, res: unknown) => void)({}, res);
    expect((res.body as Record<string, string>).status).toBe("ok");
  });

  it("resolves production environment from project suffix -prod", () => {
    process.env.GCLOUD_PROJECT = "brainforge-prod";
    const res = makeMockResponse();
    (healthCheck as unknown as (req: unknown, res: unknown) => void)({}, res);
    expect((res.body as Record<string, string>).environment).toBe("production");
  });

  it("resolves staging environment from project suffix -staging", () => {
    process.env.GCLOUD_PROJECT = "brainforge-staging";
    const res = makeMockResponse();
    (healthCheck as unknown as (req: unknown, res: unknown) => void)({}, res);
    expect((res.body as Record<string, string>).environment).toBe("staging");
  });

  it("resolves development environment from project suffix -dev", () => {
    process.env.GCLOUD_PROJECT = "brainforge-dev";
    const res = makeMockResponse();
    (healthCheck as unknown as (req: unknown, res: unknown) => void)({}, res);
    expect((res.body as Record<string, string>).environment).toBe("development");
  });

  it("defaults to development when GCLOUD_PROJECT is unset", () => {
    delete process.env.GCLOUD_PROJECT;
    const res = makeMockResponse();
    (healthCheck as unknown as (req: unknown, res: unknown) => void)({}, res);
    expect((res.body as Record<string, string>).environment).toBe("development");
  });

  it("defaults to development for an unrecognised project name", () => {
    process.env.GCLOUD_PROJECT = "some-other-project";
    const res = makeMockResponse();
    (healthCheck as unknown as (req: unknown, res: unknown) => void)({}, res);
    expect((res.body as Record<string, string>).environment).toBe("development");
  });
});
