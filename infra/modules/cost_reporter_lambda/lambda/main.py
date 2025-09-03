import os, json, datetime, urllib.request
import boto3


SLACK_WEBHOOK_URL = os.environ.get("SLACK_WEBHOOK_URL")
ce = boto3.client("ce")


def handler(event, context):
end = datetime.date.today()
start = end - datetime.timedelta(days=7)
res = ce.get_cost_and_usage(
TimePeriod={"Start": start.strftime('%Y-%m-%d'), "End": end.strftime('%Y-%m-%d')},
Granularity="DAILY",
Metrics=["BlendedCost"],
GroupBy=[{"Type":"DIMENSION","Key":"SERVICE"}]
)
days = res.get("ResultsByTime", [])
if not days:
return {"ok": True}


# Compute yesterday total + top services
y = days[-1]
total = sum(float(g["Metrics"]["BlendedCost"]["Amount"]) for g in y.get("Groups", []))
top = sorted([
(g["Keys"][0], float(g["Metrics"]["BlendedCost"]["Amount"])) for g in y.get("Groups", [])
], key=lambda x: x[1], reverse=True)[:5]


lines = [f"*AWS Daily Cost* ({y['TimePeriod']['Start']}): ${total:.2f}"]
for name, amt in top:
lines.append(f"• {name}: ${amt:.2f}")


payload = {"text": "\n".join(lines)}
req = urllib.request.Request(SLACK_WEBHOOK_URL, data=json.dumps(payload).encode('utf-8'), headers={"Content-Type":"application/json"})
urllib.request.urlopen(req)
return {"ok": True}