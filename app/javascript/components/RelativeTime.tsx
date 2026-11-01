import React, { useEffect, useState } from "react";
import { formatDate } from "../lib/dates";

type Props = {
  time: Date | string;
};

const labels = {
  second: "second",
  seconds: "seconds",
  minute: "minute",
  minutes: "minutes",
  hour: "hour",
  hours: "hours",
  day: "day",
  days: "days",
  year: "year",
  years: "years"
};

function labelledDistance(seconds: number): [number, string] {
  const minutes = seconds / 60;
  const hours = minutes / 60;
  const days = hours / 24;
  const years = days / 365;

  if (years >= 1) {
    return [years, "year"];
  } else if (days >= 1) {
    return [days, "day"];
  } else if (hours >= 1) {
    return [hours, "hour"];
  } else if (minutes >= 1) {
    return [minutes, "minute"];
  } else {
    return [seconds, "second"];
  }
}

function formattedDistance(diff: number) {
  const absDiff = Math.abs(diff);

  const [value, unit] = labelledDistance(absDiff);
  const absValue = Math.floor(value);

  let label = unit;
  if (absValue > 1) {
    label = `${label}s`;
  }

  let timeStr = `${absValue} ${labels[label]}`;
  if (absDiff < 3) {
    return "now";
  }
  if (absDiff < 60) {
    timeStr = "a moment";
  }

  if (diff < 0) {
    return `${timeStr} ago`;
  } else {
    return `in ${timeStr}`;
  }
}

export default function RelativeTime(props: Props) {
  const [currentTime, setCurrentTime] = useState(() => new Date());

  const time =
    typeof props.time == "string" ? new Date(props.time) : props.time;
  const diff = Math.ceil((time.getTime() - currentTime.getTime()) / 1000);

  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentTime(new Date());
    }, 15000);
    return () => clearInterval(interval);
  }, [props.time]);

  if (Math.abs(diff) > 60 * 60 * 24 * 14) {
    return <React.Fragment>{formatDate(time)}</React.Fragment>;
  } else {
    return <React.Fragment>{formattedDistance(diff)}</React.Fragment>;
  }
}
