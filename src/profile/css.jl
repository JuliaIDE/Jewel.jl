module CSS

css = """
  <style>
  .profile {
    position: relative;
  }
  .profile .tooltip {
    position: absolute;
    font-family: 'DejaVu Sans';
    font-size: 10pt;
    background: white;
    color: black;
    border: 1px solid #e1e1e1;
    box-shadow: 1px 1px 0px #e1e1e1;
    border-radius: 5px;
    padding: 5px;
    visibility: hidden;
    white-space: nowrap;
    pointer-events: none;
  }
  .profile .func {
    font-weight: bold;
  }
  .tree rect {
    fill: #464;
    stroke: #FFF;
    transition: fill 0.2s ease;
  }
  .tree rect:hover {
    fill: #575;
  }
  </style>
  """

end
