import { describe, it, expect, jest } from "@jest/globals";
import { eventBus } from "../src/services/realtime/EventBus";

describe("EventBus", () => {
  it("delivers published events to subscribers of the room", () => {
    const handler = jest.fn();
    eventBus.subscribe("room:a", handler);

    eventBus.publish("room:a", { type: "ping", payload: { n: 1 } });

    expect(handler).toHaveBeenCalledTimes(1);
    expect(handler).toHaveBeenCalledWith({ type: "ping", payload: { n: 1 } });
  });

  it("stops delivery after unsubscribe", () => {
    const handler = jest.fn();
    const unsub = eventBus.subscribe("room:b", handler);

    eventBus.publish("room:b", { type: "x", payload: 1 });
    unsub();
    eventBus.publish("room:b", { type: "x", payload: 2 });

    expect(handler).toHaveBeenCalledTimes(1);
  });

  it("does not deliver events to other rooms", () => {
    const handler = jest.fn();
    eventBus.subscribe("room:c", handler);

    eventBus.publish("room:d", { type: "x", payload: 1 });

    expect(handler).not.toHaveBeenCalled();
  });
});
