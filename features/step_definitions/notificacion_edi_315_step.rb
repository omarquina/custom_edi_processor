#You can implement step definitions for undefined steps with these snippets:

def get_origen

end

Given(/^Cuando se notifica que hay un nuevo RELEASE a notificar$/) do
  @origen = get_origen
end

When(/^se obtiene el detalle del equipo a notificar$/) do
  @equipo = @orgien.equipo
end

When(/^se envia via FTP$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Then(/^se notifica que fue enviado$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Given(/^Cuando se ntifica que hay un nuevo HOLD a notificar$/) do
  pending # Write code here that turns the phrase above into concrete actions
end

Given(/^que se quiere notificar un hold$/) do
  pending # Write code here that turns the phrase above into concrete actions
end
