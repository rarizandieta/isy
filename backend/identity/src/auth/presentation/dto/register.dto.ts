import { IsEmail, IsString, MaxLength, MinLength } from 'class-validator';

/** Cuerpo de POST /auth/register. */
export class RegisterDto {
  @IsString()
  @MinLength(1)
  @MaxLength(120)
  fullName!: string;

  @IsEmail()
  @MaxLength(255)
  email!: string;

  @IsString()
  @MinLength(8)
  @MaxLength(128)
  password!: string;
}
