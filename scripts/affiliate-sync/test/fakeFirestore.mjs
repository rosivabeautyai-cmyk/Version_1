/**
 * Tiny in-memory Firestore stand-in for the sync engine tests. Supports
 * exactly the surface syncEngine.mjs / testConnection.mjs use:
 *   db.collection(name).doc(id?).get()/set(data,{merge})/update(data)
 *   db.collection(name).where(field,'==',value).get()
 *   db.collection(name).get()
 *   db.batch().set(ref,data,{merge}).update(ref,data).commit()
 *   snapshot.docs -> [{ id, ref, data() }]
 */

let autoId = 0;

export class FakeFirestore {
  constructor(seed = {}) {
    /** @type {Map<string, Map<string, object>>} */
    this.data = new Map();
    for (const [col, docs] of Object.entries(seed)) {
      const m = new Map();
      for (const [id, d] of Object.entries(docs)) m.set(id, structuredClone(d));
      this.data.set(col, m);
    }
    this.commits = 0;
  }

  _col(name) {
    if (!this.data.has(name)) this.data.set(name, new Map());
    return this.data.get(name);
  }

  collection(name) {
    return new FakeCollection(this, name);
  }

  batch() {
    return new FakeBatch(this);
  }

  // test helpers
  dump(col) {
    return Object.fromEntries(this._col(col));
  }
}

class FakeCollection {
  constructor(db, name, filters = []) {
    this.db = db;
    this.name = name;
    this.filters = filters;
  }

  doc(id) {
    const realId = id || `auto_${++autoId}`;
    return new FakeDocRef(this.db, this.name, realId);
  }

  where(field, op, value) {
    if (op !== "==") throw new Error(`FakeFirestore only supports '==' (got '${op}')`);
    return new FakeCollection(this.db, this.name, [...this.filters, { field, value }]);
  }

  async get() {
    const m = this.db._col(this.name);
    let entries = [...m.entries()];
    for (const f of this.filters) {
      entries = entries.filter(([, d]) => d[f.field] === f.value);
    }
    return {
      empty: entries.length === 0,
      size: entries.length,
      docs: entries.map(([id, d]) => ({
        id,
        ref: new FakeDocRef(this.db, this.name, id),
        data: () => structuredClone(d),
      })),
    };
  }
}

class FakeDocRef {
  constructor(db, col, id) {
    this.db = db;
    this._col = col;
    this.id = id;
  }

  async get() {
    const m = this.db._col(this._col);
    const exists = m.has(this.id);
    return {
      exists,
      id: this.id,
      ref: this,
      data: () => (exists ? structuredClone(m.get(this.id)) : undefined),
    };
  }

  async set(data, opts = {}) {
    const m = this.db._col(this._col);
    if (opts.merge && m.has(this.id)) {
      m.set(this.id, { ...m.get(this.id), ...structuredClone(data) });
    } else {
      m.set(this.id, structuredClone(data));
    }
  }

  async update(data) {
    const m = this.db._col(this._col);
    if (!m.has(this.id)) throw new Error(`update on missing doc ${this._col}/${this.id}`);
    m.set(this.id, { ...m.get(this.id), ...structuredClone(data) });
  }
}

class FakeBatch {
  constructor(db) {
    this.db = db;
    this.ops = [];
  }

  set(ref, data, opts) {
    this.ops.push(() => ref.set(data, opts));
    return this;
  }

  update(ref, data) {
    this.ops.push(() => ref.update(data));
    return this;
  }

  async commit() {
    this.db.commits += 1;
    for (const op of this.ops) await op();
    this.ops = [];
  }
}
