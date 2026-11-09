import { IsEmail, IsString, MaxLength, MinLength } from 'class-validator';

/** Cuerpo de POST /auth/login. */
export class LoginDto {
  @IsEmail()
  @MaxLength(255)
  email!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(128)
  password!: string;
}
