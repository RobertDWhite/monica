<?php

namespace App\Domains\Vault\ManageVault\Api\Controllers;

use App\Domains\Contact\ManageGroups\Services\AddContactToGroup;
use App\Domains\Contact\ManageGroups\Services\CreateGroup;
use App\Domains\Contact\ManageGroups\Services\RemoveContactFromGroup;
use Illuminate\Http\Request;

/**
 * @group Contact management
 *
 * @subgroup Groups
 */
class ContactGroupApiController extends ContactModuleApiController
{
    /**
     * Add the contact to an existing group (group_id), or create a new group
     * from `name` and then add the contact.
     */
    public function store(Request $request, string $vaultId, string $contactId)
    {
        $groupId = $request->input('group_id');

        if (! $groupId) {
            $group = (new CreateGroup)->execute([
                'account_id' => $request->user()->account_id,
                'author_id' => $request->user()->id,
                'vault_id' => $vaultId,
                'group_type_id' => $request->input('group_type_id'),
                'name' => $request->input('name'),
            ]);
            $groupId = $group->id;
        }

        AddContactToGroup::dispatchSync($this->baseData($request, $vaultId, $contactId) + [
            'group_id' => (int) $groupId,
            'group_type_role_id' => $request->input('group_type_role_id'),
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }

    public function destroy(Request $request, string $vaultId, string $contactId, string $groupId)
    {
        RemoveContactFromGroup::dispatchSync($this->baseData($request, $vaultId, $contactId) + [
            'group_id' => (int) $groupId,
        ]);

        return $this->freshContact($request, $vaultId, $contactId);
    }
}
