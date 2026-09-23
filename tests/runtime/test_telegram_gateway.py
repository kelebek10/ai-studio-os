from runtime.telegram_gateway import TelegramGateway, TelegramRequest

SOURCE = "12cff6ba26a2386e1866504601177305641d7383"

def main():
    gateway = TelegramGateway({707822641})
    ok = gateway.accept(TelegramRequest(707822641, "/status", "u1"), source_commit=SOURCE)
    assert ok.allowed and ok.task is not None and ok.command == "/status"
    assert ok.task.agent == "orchestrator" and ok.task.requires_human is False
    denied_chat = gateway.accept(TelegramRequest(999999999, "/status", "u2"), source_commit=SOURCE)
    assert not denied_chat.allowed and denied_chat.reason == "TELEGRAM_CHAT_NOT_ALLOWED"
    denied_cmd = gateway.accept(TelegramRequest(707822641, "/unknown", "u3"), source_commit=SOURCE)
    assert not denied_cmd.allowed and denied_cmd.reason == "TELEGRAM_COMMAND_NOT_ALLOWED"
    approval = gateway.accept(TelegramRequest(707822641, "/approve M16", "u4"), source_commit=SOURCE)
    assert not approval.allowed and approval.reason == "TELEGRAM_APPROVAL_REQUIRES_HUMAN_GATE"
    pause = gateway.accept(TelegramRequest(707822641, "/pause", "u5"), source_commit=SOURCE)
    assert pause.allowed and pause.task is not None and pause.task.requires_human is True
    empty = gateway.accept(TelegramRequest(707822641, " ", "u6"), source_commit=SOURCE)
    assert not empty.allowed and empty.reason == "TELEGRAM_EMPTY_MESSAGE"
    print("M16.10 GATEWAY UNIT HARNESS: PASS")

if __name__ == "__main__":
    main()
