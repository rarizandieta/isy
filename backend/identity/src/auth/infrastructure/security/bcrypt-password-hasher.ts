import { Injectable } from '@nestjs/common';
import bcrypt from 'bcryptjs';
import { PasswordHasher } from '../../domain/services/password-hasher.js';

const BCRYPT_ROUNDS = 10;

/** Implementación de PasswordHasher con bcryptjs (JS puro, sin build nativo). */
@Injectable()
export class BcryptPasswordHasher extends PasswordHasher {
  hash(plain: string): Promise<string> {
    return bcrypt.hash(plain, BCRYPT_ROUNDS);
  }

  compare(plain: string, hash: string): Promise<boolean> {
    return bcrypt.compare(plain, hash);
  }
}
