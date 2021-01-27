export class ExtensionError extends Error {
    status: number;
    constructor(m: string, status?: number) {
      super(m);
      this.status = status || 500;
  
      // Set the prototype explicitly.
      Object.setPrototypeOf(this, ExtensionError.prototype);
    }
  }
  