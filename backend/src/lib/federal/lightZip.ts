/**
 * lightZip.ts — read files out of a ZIP held in memory, with almost no per-file overhead.
 *
 * Why not adm-zip: it builds a heavy object per file (about 9 KB each). LegiScan's US Congress dataset
 * has 21,446 files, so the table alone took ~200 MiB of heap for as long as the archive was open, and a
 * 512 MiB job crashed. This reads the ZIP's central directory once into a Map of name -> three numbers
 * (about 100 bytes a file) and inflates a file only when asked.
 *
 * Supports stored and deflated entries in an ordinary (non-zip64) archive, which is what LegiScan sends.
 */
import { inflateRawSync } from 'node:zlib';

interface Entry { offset: number; compressedSize: number; method: number }

export class LightZip {
  private readonly entries = new Map<string, Entry>();

  constructor(private readonly buf: Buffer) {
    // End-of-central-directory record: the last 22+ bytes, found by its signature.
    let eocd = -1;
    for (let i = buf.length - 22; i >= Math.max(0, buf.length - 22 - 65_535); i--) {
      if (buf.readUInt32LE(i) === 0x06054b50) { eocd = i; break; }
    }
    if (eocd < 0) throw new Error('not a ZIP archive (no end record)');
    const count = buf.readUInt16LE(eocd + 10);
    const dirOffset = buf.readUInt32LE(eocd + 16);
    if (count === 0xffff || dirOffset === 0xffffffff) throw new Error('zip64 archives are not supported');

    let p = dirOffset;
    for (let n = 0; n < count; n++) {
      if (buf.readUInt32LE(p) !== 0x02014b50) throw new Error('corrupt ZIP central directory');
      const method = buf.readUInt16LE(p + 10);
      const compressedSize = buf.readUInt32LE(p + 20);
      const nameLen = buf.readUInt16LE(p + 28);
      const extraLen = buf.readUInt16LE(p + 30);
      const commentLen = buf.readUInt16LE(p + 32);
      const offset = buf.readUInt32LE(p + 42);
      const name = buf.toString('utf8', p + 46, p + 46 + nameLen);
      if (!name.endsWith('/')) this.entries.set(name, { offset, compressedSize, method });
      p += 46 + nameLen + extraLen + commentLen;
    }
  }

  /** Every file name (directories excluded). */
  get names(): string[] { return [...this.entries.keys()]; }

  get size(): number { return this.entries.size; }

  /** The bytes of one file, or undefined when it is not in the archive. */
  read(name: string): Buffer | undefined {
    const e = this.entries.get(name);
    if (!e) return undefined;
    if (this.buf.readUInt32LE(e.offset) !== 0x04034b50) throw new Error(`corrupt ZIP entry: ${name}`);
    const start = e.offset + 30 + this.buf.readUInt16LE(e.offset + 26) + this.buf.readUInt16LE(e.offset + 28);
    const raw = this.buf.subarray(start, start + e.compressedSize);
    if (e.method === 0) return Buffer.from(raw);
    if (e.method === 8) return inflateRawSync(raw);
    throw new Error(`unsupported ZIP method ${e.method}: ${name}`);
  }

  /** One JSON file, parsed; undefined when missing or not valid JSON. */
  readJson(name: string): any | undefined { // eslint-disable-line @typescript-eslint/no-explicit-any
    const data = this.read(name);
    if (!data) return undefined;
    try { return JSON.parse(data.toString('utf8')); } catch { return undefined; }
  }
}
