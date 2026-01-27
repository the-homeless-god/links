import * as TE from 'fp-ts/TaskEither';
import { pipe } from 'fp-ts/function';
import type { Link, ExportData } from '@/types';
import { getAuthState, getApiUrl } from './storage';
import { log } from './logger';

export const getAuthHeaders = (): TE.TaskEither<Error, Record<string, string>> =>
  pipe(
    getAuthState(),
    TE.map(({ authToken }) => {
      const headers: Record<string, string> = {
        'Content-Type': 'application/json',
      };

      if (authToken === 'guest') {
        headers['X-Guest-Token'] = 'guest';
      } else if (authToken) {
        headers['Authorization'] = `Bearer ${authToken}`;
      }

      return headers;
    })
  );

export const fetchLinks = (): TE.TaskEither<Error, Link[]> =>
  pipe(
    TE.Do,
    TE.bind('apiUrl', () => getApiUrl()),
    TE.bind('headers', () => getAuthHeaders()),
    TE.chain(({ apiUrl, headers }) =>
      TE.tryCatch(
        async () => {
          const response = await fetch(`${apiUrl}/api/links`, { headers });

          if (!response.ok) {
            if (response.status === 401) {
              throw new Error('UNAUTHORIZED');
            }
            throw new Error(`HTTP error! status: ${response.status}`);
          }

          const links = await response.json();
          return Array.isArray(links) ? links : [];
        },
        (error) => new Error(`Failed to fetch links: ${error}`)
      )
    )
  );

export const createLink = (linkData: Partial<Link>): TE.TaskEither<Error, Link> =>
  pipe(
    TE.Do,
    TE.bind('apiUrl', () => getApiUrl()),
    TE.bind('headers', () => getAuthHeaders()),
    TE.chain(({ apiUrl, headers }) =>
      TE.tryCatch(
        async () => {
          const response = await fetch(`${apiUrl}/api/links`, {
            method: 'POST',
            headers,
            body: JSON.stringify(linkData),
          });

          if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            throw new Error(
              (errorData as { message?: string }).message ||
                `HTTP error! status: ${response.status}`
            );
          }

          return (await response.json()) as Link;
        },
        (error) => new Error(`Failed to create link: ${error}`)
      )
    )
  );

export const updateLink = (
  id: string,
  linkData: Partial<Link>
): TE.TaskEither<Error, Link> =>
  pipe(
    TE.Do,
    TE.bind('apiUrl', () => getApiUrl()),
    TE.bind('headers', () => getAuthHeaders()),
    TE.chain(({ apiUrl, headers }) =>
      TE.tryCatch(
        async () => {
          const response = await fetch(`${apiUrl}/api/links/${id}`, {
            method: 'PUT',
            headers,
            body: JSON.stringify(linkData),
          });

          if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            throw new Error(
              (errorData as { message?: string }).message ||
                `HTTP error! status: ${response.status}`
            );
          }

          return (await response.json()) as Link;
        },
        (error) => new Error(`Failed to update link: ${error}`)
      )
    )
  );

export const deleteLink = (id: string): TE.TaskEither<Error, void> =>
  pipe(
    TE.Do,
    TE.bind('apiUrl', () => getApiUrl()),
    TE.bind('headers', () => getAuthHeaders()),
    TE.chain(({ apiUrl, headers }) =>
      TE.tryCatch(
        async () => {
          const response = await fetch(`${apiUrl}/api/links/${id}`, {
            method: 'DELETE',
            headers,
          });

          if (response.status !== 204 && response.status !== 200) {
            throw new Error(`HTTP error! status: ${response.status}`);
          }
        },
        (error) => new Error(`Failed to delete link: ${error}`)
      )
    )
  );

export const exportLinks = (): TE.TaskEither<Error, ExportData> =>
  pipe(
    fetchLinks(),
    TE.map((links) => ({
      version: '1.0',
      exportDate: new Date().toISOString(),
      count: links.length,
      links,
    }))
  );

export const importLinks = (
  links: Link[]
): TE.TaskEither<Error, { success: number; errors: string[] }> =>
  TE.tryCatch(
    async () => {
      let successCount = 0;
      const errors: string[] = [];

      for (const link of links) {
        try {
          if (!link.name || !link.url) {
            errors.push(`Ссылка без имени или URL пропущена`);
            continue;
          }

          const linkData = {
            name: link.name,
            url: link.url,
            description: link.description || '',
            group_id: link.group_id || '',
          };

          const result = await createLink(linkData)();
          if ('right' in result) {
            successCount++;
          } else {
            const errorMessage = result.left.message;
            if (errorMessage.includes('name_already_exists')) {
              successCount++;
            } else {
              errors.push(`${linkData.name}: ${errorMessage}`);
            }
          }
        } catch (error) {
          const errorMessage = error instanceof Error ? error.message : String(error);
          errors.push(`${link.name || 'Неизвестная'}: ${errorMessage}`);
        }
      }

      return { success: successCount, errors };
    },
    (error) => new Error(`Failed to import links: ${error}`)
  );
