export type AppRole = 'child' | 'elder';

export interface AuthenticatedUser {
  sub: string;
  role: AppRole;
}

export interface AccessTokenPayload extends AuthenticatedUser {
  type: 'access';
  iat: number;
  exp: number;
}

export interface PublicUser {
  id: string;
  role: AppRole;
  nickname: string;
}
