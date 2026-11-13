import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { AuthService } from './application/services/auth.service.js';
import { AuthServiceImpl } from './application/services/auth.service.impl.js';
import { SessionRepository } from './domain/repositories/session.repository.js';
import { UserRepository } from './domain/repositories/user.repository.js';
import { PasswordHasher } from './domain/services/password-hasher.js';
import { TokenBlocklist } from './domain/services/token-blocklist.js';
import { TokenService } from './domain/services/token.service.js';
import { DrizzleSessionRepository } from './infrastructure/persistence/drizzle-session.repository.js';
import { DrizzleUserRepository } from './infrastructure/persistence/drizzle-user.repository.js';
import { BcryptPasswordHasher } from './infrastructure/security/bcrypt-password-hasher.js';
import { JwtTokenService } from './infrastructure/security/jwt-token.service.js';
import { RedisTokenBlocklist } from './infrastructure/security/redis-token-blocklist.js';
import { AuthController } from './presentation/auth.controller.js';
import { JwtAuthGuard } from './presentation/guards/jwt-auth.guard.js';
import { ProfilesController } from './presentation/profiles.controller.js';

/**
 * Módulo auth (Clean Architecture). El binding puerto -> implementación hace la
 * inversión de dependencias: presentación y aplicación dependen de las
 * abstracciones (AuthService, *Repository, PasswordHasher, TokenService), y aquí
 * se decide qué implementación concreta de infraestructura se inyecta.
 */
@Module({
  imports: [
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.getOrThrow<string>('JWT_SECRET'),
        // TODO: migrar a RS256 con el gateway (identity firma con la privada,
        // el gateway valida con la pública).
        signOptions: { algorithm: 'HS256' },
        verifyOptions: { algorithms: ['HS256'] },
      }),
    }),
  ],
  controllers: [AuthController, ProfilesController],
  providers: [
    { provide: AuthService, useClass: AuthServiceImpl },
    { provide: UserRepository, useClass: DrizzleUserRepository },
    { provide: SessionRepository, useClass: DrizzleSessionRepository },
    { provide: PasswordHasher, useClass: BcryptPasswordHasher },
    { provide: TokenService, useClass: JwtTokenService },
    { provide: TokenBlocklist, useClass: RedisTokenBlocklist },
    JwtAuthGuard,
  ],
})
export class AuthModule {}
