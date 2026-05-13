export const ALLOWED_AGE_RANGES = ["5-7", "8-10", "11-13"] as const;
export type AgeRange = (typeof ALLOWED_AGE_RANGES)[number];

export const ALLOWED_AVATAR_IDS = [
  "avatar_1", "avatar_2", "avatar_3",
  "avatar_4", "avatar_5", "avatar_6",
] as const;
export type AvatarId = (typeof ALLOWED_AVATAR_IDS)[number];

export function isValidUsername(username: string): boolean {
  return /^[a-zA-Z0-9_]{3,20}$/.test(username);
}

export function isValidPin(pin: string): boolean {
  return /^\d{4}$/.test(pin);
}

export function isAllowedAgeRange(value: string): value is AgeRange {
  return ALLOWED_AGE_RANGES.includes(value as AgeRange);
}

export function isAllowedAvatarId(value: string): value is AvatarId {
  return ALLOWED_AVATAR_IDS.includes(value as AvatarId);
}
