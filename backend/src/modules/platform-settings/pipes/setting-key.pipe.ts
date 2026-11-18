import { BadRequestException, Injectable, PipeTransform } from '@nestjs/common';

export const SETTING_KEY_REGEX = /^[a-zA-Z0-9._-]+$/;
export const SETTING_KEY_MAX_LENGTH = 100;

export function assertValidSettingKey(key: string): string {
  if (
    typeof key !== 'string' ||
    key.length < 1 ||
    key.length > SETTING_KEY_MAX_LENGTH ||
    !SETTING_KEY_REGEX.test(key)
  ) {
    throw new BadRequestException(
      'Setting key must be 1 to 100 characters and match ^[a-zA-Z0-9._-]+$',
    );
  }
  return key;
}

@Injectable()
export class SettingKeyPipe implements PipeTransform<string, string> {
  transform(value: string): string {
    return assertValidSettingKey(value);
  }
}
