class Delegate {
    construct new() {
        _listeners = {}
    }

    addListener(id, callback) {
        _listeners[id] = callback
        System.print("Listener added for %(callback)")
    }

    removeListener(id) {
        if (_listeners.containsKey(id)) {
            _listeners.remove(id)
        }
    }

    notify(packet) {
        for (listener in _listeners) listener.value.call(packet)
    }

    listeners {_listeners}
}


class PerkTrigger is Delegate {
    construct new() {
        super()
    }

    notify(who, packet) {
        for (listener in listeners) listener.value.call(packet)
    }
}