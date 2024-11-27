  $ graphjs parse if.js
  if (10) {
    
  }
  if (10) {
    
  }
  if (10) {
    x;
  }
  if (10) {
    x;
  }
  if (10) {
    x;
  } else {
    y;
  }
  if (10) {
    x;
  } else {
    y;
  }
  if (10) {
    x;
  } else {
    if ("abc") {
      y;
    } else {
      z;
    }
  }
  if (10) {
    x;
  } else {
    if ("abc") {
      y;
    } else {
      z;
    }
  }
  if (10) {
    if ("abc") {
      x;
    } else {
      y;
    }
  } else {
    z;
  }
  let $v1 = 10 + "abc";
  let $v2 = $v1 == true;
  if ($v2) {
    x;
  }

  $ graphjs parse switch.js
  switch (foo) {
    
  }
  switch (foo) {
    case 10:
      
  }
  switch (foo) {
    case 10:
      x;
  }
  switch (foo) {
    case 10:
      
    case "abc":
      
    case true:
      
  }
  switch (foo) {
    case 10:
      x;
    case "abc":
      y;
    case true:
      z;
  }
  switch (foo) {
    case 10:
      x;
    default:
      y;
  }
  switch (foo) {
    case 10:
      x;
    default:
      y;
    case "abc":
      z;
  }
  switch (foo) {
    case 10:
      switch (bar) {
        case "abc":
          y;
      }
    case true:
      z;
  }
  let $v1 = foo + bar;
  switch ($v1) {
    case 10:
      x;
  }
  let $v2 = 10 + "abc";
  switch (foo) {
    case $v2:
      x;
  }
  let $v3 = foo + bar;
  let $v4 = 10 + "abc";
  switch ($v3) {
    case $v4:
      x;
  }
