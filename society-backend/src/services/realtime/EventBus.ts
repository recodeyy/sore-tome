// Tiny in-process pub/sub. No external dependencies.
// Used by the realtime SSE gateway and the outbox publisher.

export type RealtimeEvent = {
  type: string;
  payload: any;
  id?: string | number;
};

type Handler = (event: RealtimeEvent) => void;

class EventBus {
  private rooms: Map<string, Set<Handler>> = new Map();

  /**
   * Subscribe a handler to a room. Returns an unsubscribe function.
   */
  subscribe(room: string, fn: Handler): () => void {
    let set = this.rooms.get(room);
    if (!set) {
      set = new Set<Handler>();
      this.rooms.set(room, set);
    }
    set.add(fn);

    return () => {
      const current = this.rooms.get(room);
      if (!current) return;
      current.delete(fn);
      if (current.size === 0) this.rooms.delete(room);
    };
  }

  /**
   * Publish an event to every subscriber of a room.
   */
  publish(room: string, event: RealtimeEvent): void {
    const set = this.rooms.get(room);
    if (!set) return;
    // Copy so handlers that unsubscribe mid-iteration don't break the loop.
    for (const fn of Array.from(set)) {
      fn(event);
    }
  }
}

export const eventBus = new EventBus();
